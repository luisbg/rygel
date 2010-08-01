/*
 * Copyright (C) 2008,2010 Nokia Corporation.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
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

public class Rygel.MediaRendererPlugin : Rygel.Plugin {
    private static const string MEDIA_RENDERER_DESC_PATH =
                                BuildConfig.DATA_DIR +
                                "/xml/MediaRenderer2.xml";

    public MediaRendererPlugin (string  name,
                                string? title,
                                Type    connection_manager_type,
                                Type    av_transport_type,
                                Type    rendering_control_type,
                                string? description = null) {
        base (MEDIA_RENDERER_DESC_PATH, name, title, description);

        var resource = new ResourceInfo (ConnectionManager.UPNP_ID,
                                         ConnectionManager.UPNP_TYPE,
                                         ConnectionManager.DESCRIPTION_PATH,
                                         connection_manager_type);
        this.add_resource (resource);

        resource = new ResourceInfo (Rygel.AVTransport.UPNP_ID,
                                     Rygel.AVTransport.UPNP_TYPE,
                                     Rygel.AVTransport.DESCRIPTION_PATH,
                                     av_transport_type);
        this.add_resource (resource);

        resource = new ResourceInfo (RenderingControl.UPNP_ID,
                                     RenderingControl.UPNP_TYPE,
                                     RenderingControl.DESCRIPTION_PATH,
                                     rendering_control_type);
        this.add_resource (resource);
    }
}

