/*
 * Copyright (C) 2010 Jens Georg <mail@jensge.org>.
 *
 * Author: Jens Georg <mail@jensge.org>
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
using Gee;

internal class Rygel.MediaExport.WritableDbContainer : DBContainer,
                                                    Rygel.WritableContainer {
    public ArrayList<string> create_classes { get; set; }

    public WritableDbContainer (MediaCache media_db, string id, string title) {
        base (media_db, id, title);

        this.create_classes = new ArrayList<string> ();
        this.create_classes.add (ImageItem.UPNP_CLASS);
        this.create_classes.add (PhotoItem.UPNP_CLASS);
        this.create_classes.add (VideoItem.UPNP_CLASS);
        this.create_classes.add (AudioItem.UPNP_CLASS);
        this.create_classes.add (MusicItem.UPNP_CLASS);
    }

    public async void add_item (Rygel.MediaItem item, Cancellable? cancellable)
                                throws Error {
        item.parent = this;
        item.id = MediaCache.get_id (File.new_for_uri (item.uris[0]));
        this.media_db.save_item (item);
    }

    public async void remove_item (string id, Cancellable? cancellable)
                                   throws Error {
        this.media_db.remove_by_id (id);
    }
}
