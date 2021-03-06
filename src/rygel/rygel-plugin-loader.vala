/*
 * Copyright (C) 2008 Nokia Corporation.
 * Copyright (C) 2008 Zeeshan Ali (Khattak) <zeeshanak@gnome.org>.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *
 * This file is part of Rygel.
 *
 * Rygel is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * Rygel is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 */

using GUPnP;
using Gee;

/**
 * Responsible for plugin loading. Probes for shared library files in a specific
 * directry and tries to grab a function with a specific name and signature,
 * calls it. The loaded module can then add plugins to Rygel by calling the
 * add_plugin method. NOTE: The module SHOULD make sure that plugin is not
 * disabled by user using plugin_disabled method before creating the plugin
 * instance and resources related to that instance.
 */
public class Rygel.PluginLoader : Object {
    private delegate void ModuleInitFunc (PluginLoader loader);

    private HashMap<string,Plugin> plugin_hash;

    // Signals
    public signal void plugin_available (Plugin plugin);

    public PluginLoader () {
        this.plugin_hash = new HashMap<string,Plugin> (str_hash, str_equal);
    }

    // Plugin loading functions
    public void load_plugins () {
        assert (Module.supported());

        string path;
        try {
            var config = MetaConfig.get_default ();
            path = config.get_plugin_path ();
        } catch (Error error) {
            path = BuildConfig.PLUGIN_DIR;
        }

        File dir = File.new_for_path (path);
        assert (dir != null && is_dir (dir));

        this.load_modules_from_dir.begin (dir);
    }

    /**
     * Checks if a plugin is disabled by user
     *
     * @param name the name of plugin to check for.
     *
     * return true if plugin is disabled, false if not.
     */
    public bool plugin_disabled (string name) {
        var enabled = true;
        try {
            var config = MetaConfig.get_default ();
            enabled = config.get_enabled (name);
        } catch (GLib.Error err) {}

        return !enabled;
    }

    public void add_plugin (Plugin plugin) {
        message (_("New plugin '%s' available"), plugin.name);
        this.plugin_hash.set (plugin.name, plugin);
        this.plugin_available (plugin);
    }

    public Plugin? get_plugin_by_name (string name) {
        return this.plugin_hash.get (name);
    }

    public Collection<Plugin> list_plugins () {
        return this.plugin_hash.values;
    }

    private async void load_modules_from_dir (File dir) {
        debug ("Searching for modules in folder '%s'.", dir.get_path ());

        string attributes = FILE_ATTRIBUTE_STANDARD_NAME + "," +
                            FILE_ATTRIBUTE_STANDARD_TYPE + "," +
                            FILE_ATTRIBUTE_STANDARD_CONTENT_TYPE;

        GLib.List<FileInfo> infos;
        FileEnumerator enumerator;

        try {
            enumerator = yield dir.enumerate_children_async
                                        (attributes,
                                         FileQueryInfoFlags.NONE,
                                         Priority.DEFAULT,
                                         null);

            infos = yield enumerator.next_files_async (int.MAX,
                                                       Priority.DEFAULT,
                                                       null);
        } catch (Error error) {
            critical (_("Error listing contents of folder '%s': %s"),
                      dir.get_path (),
                      error.message);

            return;
        }

        foreach (var info in infos) {
            string file_name = info.get_name ();
            string file_path = Path.build_filename (dir.get_path (), file_name);

            File file = File.new_for_path (file_path);
            FileType file_type = info.get_file_type ();
            string content_type = info.get_content_type ();
            string mime = ContentType.get_mime_type (content_type);

            if (file_type == FileType.DIRECTORY) {
                // Recurse into directories
                this.load_modules_from_dir.begin (file);
            } else if (mime == "application/x-sharedlib") {
                // Seems like we found a module
                this.load_module_from_file (file_path);
            }
        }

        debug ("Finished searching for modules in folder '%s'",
               dir.get_path ());
    }

    private void load_module_from_file (string file_path) {
        Module module = Module.open (file_path, ModuleFlags.BIND_LOCAL);
        if (module == null) {
            warning (_("Failed to load module from path '%s': %s"),
                     file_path,
                     Module.error ());

            return;
        }

        void* function;

        if (!module.symbol("module_init", out function)) {
            warning (_("Failed to find entry point function '%s' in '%s': %s"),
                     "module_init",
                     file_path,
                     Module.error ());

            return;
        }

        unowned ModuleInitFunc module_init = (ModuleInitFunc) function;
        assert (module_init != null);

        // We don't want our modules to ever unload
        module.make_resident ();

        module_init (this);

        debug ("Loaded module source: '%s'", module.name());
    }

    private static bool is_dir (File file) {
        FileInfo file_info;

        try {
            file_info = file.query_info (FILE_ATTRIBUTE_STANDARD_TYPE,
                                         FileQueryInfoFlags.NONE,
                                         null);
        } catch (Error error) {
            critical (_("Failed to query content type for '%s'"),
                      file.get_path ());

            return false;
        }

        return file_info.get_file_type () == FileType.DIRECTORY;
    }
}

