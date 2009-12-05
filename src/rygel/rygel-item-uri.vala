/*
 * Copyright (C) 2009 Jens Georg <mail@jensge.org>.
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

internal class Rygel.ItemUri : Object {
    public string item_id;
    public int thumbnail_index;
    public string? transcode_target;

    public ItemUri (string item_id,
                    int thumbnail_index = -1,
                    string ? transcode_target = null) {
        this.item_id = item_id;
        this.thumbnail_index = thumbnail_index;
        this.transcode_target = transcode_target;
    }

    public ItemUri.from_string (string uri, string server_root = "") {
        // do not decode the path here as it may contain encoded slashes
        this.thumbnail_index = -1;
        this.transcode_target = null;
        var request_uri = uri.replace (server_root, "");
        var parts = request_uri.split ("/");
        if (parts.length < 2 || parts.length % 2 == 0)
            warning ("Invalid uri %s", request_uri);
        else {
            for (int i = 1; i < parts.length - 1; i += 2) {
                switch (parts[i]) {
                    case "item":
                        this.item_id = Soup.URI.decode (parts[i + 1]);
                        break;
                    case "transcoded":
                        this.transcode_target = Soup.URI.decode (parts[i + 1]);
                        break;
                    case "thumbnail":
                        this.thumbnail_index = parts[i + 1].to_int ();
                        break;
                    default:
                        break;
                }
            }
        }
    }

    public string to_string() {
        string escaped = Uri.escape_string (item_id, "", true);
        string query = "/item/" + escaped;

        if (transcode_target != null) {
            escaped = Uri.escape_string (transcode_target, "", true);
            query += "/transcoded/" + escaped;
        } else if (thumbnail_index >= 0) {
            query += "/thumbnail/" + thumbnail_index.to_string ();
        }

        return query;
    }
}
