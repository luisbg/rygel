/*
 * Copyright (C) 2009 Jens Georg
 *
 * Author: Jens Georg <mail@jensge.org>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 */

using GLib;
using Rygel;
using Xml;

public errordomain Rygel.MediathekVideoItemError {
    XML_PARSE_ERROR
}

public class Rygel.MediathekVideoItem : Rygel.MediaItem {
    private MediathekVideoItem(MediaContainer parent, string title) {
        base(Checksum.compute_for_string(ChecksumType.MD5, title), parent, title, MediaItem.VIDEO_CLASS);
        this.mime_type = "video/x-ms-asf";
        this.author = "ZDF - Zweites Deutsches Fernsehen";
    }

    private static bool namespace_ok(Xml.Node* node) {
        return node->ns != null && node->ns->prefix == "media";
    }

    public static MediathekVideoItem create_from_xml(MediaContainer parent, Xml.Node *item) throws MediathekVideoItemError {
        string title = null;
        MediathekVideoItem video_item = null;
        MediathekAsxPlaylist asx = null;

        for (Xml.Node* item_child = item->children; item_child != null; item_child = item_child->next)
        {
            switch (item_child->name) {
                case "title":
                    title = item_child->get_content();
                    break;
                case "group":
                    if (namespace_ok(item_child)) {
                        for (Xml.Node* group = item_child->children; 
                             group != null;
                             group = group->next) {
                            if (group->name == "content") {
                                if (namespace_ok(group)) {
                                    Xml.Attr* attr = group->has_prop("url");
                                    if (attr != null) {
                                        var url = attr->children->content;
                                        if (url.has_suffix(".asx")) {
                                            debug("Found Url %s", url);
                                            asx = new MediathekAsxPlaylist(url);
                                            asx.parse();
                                        }
                                    }
                                    else {
                                        throw new MediathekVideoItemError.XML_PARSE_ERROR("group node has url property");
                                    }
                                }
                                else {
                                    throw new MediathekVideoItemError.XML_PARSE_ERROR("invalid or no namespace");
                                }
                            }
                        }
                    }
                    else {
                        throw new MediathekVideoItemError.XML_PARSE_ERROR("invalid or no namespace on group node");
                    }
                    break;
                default:
                    //debug("Got node->name %s", node->name);
                    break;
             }

        }
        if (title == null) {
            throw new MediathekVideoItemError.XML_PARSE_ERROR("Could not find title");
        }


        if (asx == null) {
            throw new MediathekVideoItemError.XML_PARSE_ERROR("Could not find uris");
        }

        video_item = new MediathekVideoItem(parent, title);
        foreach (string uri in asx.uris) {
            video_item.uris.add(uri);
        }

        return video_item;
    }
}