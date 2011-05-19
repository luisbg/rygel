/*
 * Copyright (C) 2008-2010 Nokia Corporation.
 * Copyright (C) 2006, 2007, 2008 OpenedHand Ltd.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
 *         Jorn Baayen <jorn.baayen@gmail.com>
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

using Gst;

/**
 * Responsible for handling HTTP GET & HEAD client requests.
 */
internal class Rygel.HTTPGet : HTTPRequest {
    private const string TRANSFER_MODE_HEADER = "transferMode.dlna.org";

    public Thumbnail thumbnail;
    public Subtitle subtitle;
    public HTTPSeek seek;

    private int thumbnail_index;
    private int subtitle_index;

    public HTTPGetHandler handler;

    public HTTPGet (HTTPServer   http_server,
                    Soup.Server  server,
                    Soup.Message msg) {
        base (http_server, server, msg);

        this.thumbnail_index = -1;
        this.subtitle_index = -1;
    }

    protected override async void handle () throws Error {
        var header = this.msg.request_headers.get_one
                                        ("getcontentFeatures.dlna.org");

        /* We only entertain 'HEAD' and 'GET' requests */
        if ((this.msg.method != "HEAD" && this.msg.method != "GET") ||
            (header != null && header != "1")) {
            throw new HTTPRequestError.BAD_REQUEST (_("Invalid Request"));
        }

        if (uri.transcode_target != null) {
            var transcoder = this.http_server.get_transcoder
                                        (uri.transcode_target);
            this.handler = new HTTPTranscodeHandler (transcoder,
                                                     this.cancellable);
        }

        if (this.handler == null) {
            this.handler = new HTTPIdentityHandler (this.cancellable);
        }

        this.ensure_correct_mode ();

        yield this.handle_item_request ();
    }

    protected override async void find_item () throws Error {
        yield base.find_item ();

        if (unlikely (this.item.place_holder)) {
            throw new HTTPRequestError.NOT_FOUND ("Item '%s' is empty",
                                                  this.item.id);
        }

        try {
            var hack = new XBoxHacks.for_headers (this.msg.request_headers);
            if (hack.is_album_art_request (this.msg) &&
                this.item is VisualItem) {
                var visual_item = this.item as VisualItem;

                if (visual_item.thumbnails.size <= 0) {
                    throw new HTTPRequestError.NOT_FOUND ("No Thumbnail " +
                                                          "available for " +
                                                          "item '%s'",
                                                          visual_item.id);
                }

                this.thumbnail = visual_item.thumbnails.get (0);

                return;
            }
        } catch (XBoxHacksError error) {}

        if (this.uri.thumbnail_index >= 0) {
            if (this.item is MusicItem) {
                var music = this.item as MusicItem;

                this.thumbnail = music.album_art;
            } else if (this.item is VisualItem) {
                var visual = this.item as VisualItem;

                this.thumbnail = visual.thumbnails.get
                                        (this.uri.thumbnail_index);
            } else {
                throw new HTTPRequestError.NOT_FOUND
                                        ("No Thumbnail available for item '%s",
                                         this.item.id);
            }
        } else if (this.uri.subtitle_index >= 0) {
            if (!(this.item is VideoItem)) {
                throw new HTTPRequestError.NOT_FOUND
                                        ("No subtitles available for item '%s",
                                         this.item.id);
            }

            this.subtitle = (this.item as VideoItem).subtitles.get
                                        (this.uri.subtitle_index);
        }
    }

    private async void handle_item_request () throws Error {
        var need_time_seek = HTTPTimeSeek.needed (this);
        var need_byte_seek = HTTPByteSeek.needed (this);

        if ((HTTPTimeSeek.requested (this) && !need_time_seek) ||
            (HTTPByteSeek.requested (this) && !need_byte_seek)) {
            throw new HTTPRequestError.UNACCEPTABLE ("Invalid seek request");
        }

        try {
            if (need_time_seek) {
                this.seek = new HTTPTimeSeek (this);
            } else if (need_byte_seek) {
                this.seek = new HTTPByteSeek (this);
            }
        } catch (HTTPSeekError error) {
            this.server.unpause_message (this.msg);

            if (error is HTTPSeekError.INVALID_RANGE) {
                this.end (Soup.KnownStatusCode.BAD_REQUEST);
            } else if (error is HTTPSeekError.OUT_OF_RANGE) {
                this.end (Soup.KnownStatusCode.REQUESTED_RANGE_NOT_SATISFIABLE);
            } else {
                throw error;
            }

            return;
        }

        // Add headers
        this.handler.add_response_headers (this);
        debug ("Following HTTP headers appended to response:");
        this.msg.response_headers.foreach ((name, value) => {
            debug ("%s : %s", name, value);
        });

        if (this.msg.method == "HEAD") {
            // Only headers requested, no need to send contents
            this.server.unpause_message (this.msg);
            this.end (Soup.KnownStatusCode.OK);

            return;
        }

        var response = this.handler.render_body (this);

        yield response.run ();

        this.end (Soup.KnownStatusCode.NONE);
    }

    private void ensure_correct_mode () throws HTTPRequestError {
        var mode = this.msg.request_headers.get_one (TRANSFER_MODE_HEADER);
        var correct = true;

        switch (mode) {
        case "Streaming":
            correct = this.handler is HTTPTranscodeHandler ||
                      (this.item.streamable () &&
                       this.subtitle == null &&
                       this.thumbnail == null);

            break;
        case "Interactive":
            correct =  this.handler is HTTPIdentityHandler &&
                       (!this.item.is_live_stream () ||
                        this.subtitle != null ||
                        this.thumbnail != null) &&
                       !this.item.streamable ();

            break;
        }

        if (!correct) {
            throw new HTTPRequestError.UNACCEPTABLE
                                        ("%s mode not supported for '%s'",
                                         mode,
                                         this.item.id);
        }
    }
}

