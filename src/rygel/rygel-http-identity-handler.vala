/*
 * Copyright (C) 2008, 2009 Nokia Corporation.
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

using GUPnP;

// An HTTP request handler that passes the item content through as is.
internal class Rygel.HTTPIdentityHandler : Rygel.HTTPRequestHandler {

    public HTTPIdentityHandler (Cancellable? cancellable) {
        this.cancellable = cancellable;
    }

    public override void add_response_headers (HTTPRequest request)
                                               throws HTTPRequestError {
        if (request.thumbnail != null) {
            request.msg.response_headers.append ("Content-Type",
                                                 request.thumbnail.mime_type);
        } else {
            request.msg.response_headers.append ("Content-Type",
                                                 request.item.mime_type);
        }

        if (request.seek != null) {
            request.seek.add_response_headers ();
        }

        // Chain-up
        base.add_response_headers (request);
    }

    public override HTTPResponse render_body (HTTPRequest request)
                                              throws HTTPRequestError {
        try {
            return this.render_body_real (request);
        } catch (Error err) {
            throw new HTTPRequestError.NOT_FOUND (err.message);
        }
    }

    protected override DIDLLiteResource add_resource (DIDLLiteItem didl_item,
                                                      HTTPRequest  request)
                                                      throws Error {
        var protocol = request.http_server.get_protocol ();

        if (request.thumbnail != null) {
            return request.thumbnail.add_resource (didl_item, protocol);
        } else {
            return request.item.add_resource (didl_item, null, protocol);
        }
    }

    private HTTPResponse render_body_real (HTTPRequest request) throws Error {
        if (request.thumbnail != null) {
            return new SeekableResponse (request.server,
                                         request.msg,
                                         request.thumbnail.uri,
                                         request.seek,
                                         request.thumbnail.size,
                                         this.cancellable);
        }

        var item = request.item;

        if (item.should_stream ()) {
            Gst.Element src = item.create_stream_source ();
            if (src == null) {
                throw new HTTPRequestError.NOT_FOUND ("Not found");
            }

            return new LiveResponse (request.server,
                                     request.msg,
                                     "RygelLiveResponse",
                                     src,
                                     request.seek,
                                     this.cancellable);
        } else {
            if (item.uris.size == 0) {
                throw new HTTPRequestError.NOT_FOUND (
                        "Requested item '%s' didn't provide a URI\n",
                        item.id);
            }

            return new SeekableResponse (request.server,
                                         request.msg,
                                         item.uris.get (0),
                                         request.seek,
                                         item.size,
                                         this.cancellable);
        }
    }
}
