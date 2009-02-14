/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 * Copyright (C) 2008 Nokia Corporation, all rights reserved.
 *
 * Author: Zeeshan Ali <zeenix@gmail.com>
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

using Rygel;

/**
 * Represents Tracker Image category.
 */
public class Rygel.TrackerImageContainer : Rygel.TrackerContainer {
    public TrackerImageContainer (string id,
                                  string parent_id,
                                  string title) {
        base (id, parent_id, title, "Images", MediaItem.IMAGE_CLASS);
    }

    protected override MediaItem? fetch_item_by_path (string path)
                                                      throws GLib.Error {
        return new TrackerImageItem (this.id + ":" + path,
                                     path,
                                     this,
                                     null);
    }
}

