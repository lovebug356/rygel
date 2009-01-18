/*
 * Copyright (C) 2008 Nokia Corporation, all rights reserved.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
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
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 */

using Gst;

public class Rygel.HTTPResponse : GLib.Object {
    public Soup.Server server { get; private set; }
    protected Soup.Message msg;

    public signal void ended ();

    public HTTPResponse (Soup.Server  server,
                         Soup.Message msg,
                         bool         partial) {
        this.server = server;
        this.msg = msg;

        server.pause_message (this.msg);

        if (partial) {
            this.msg.set_status (Soup.KnownStatusCode.PARTIAL_CONTENT);
        } else {
            this.msg.set_status (Soup.KnownStatusCode.OK);
        }

        this.server.request_aborted += on_request_aborted;
    }

    private void on_request_aborted (Soup.Server        server,
                                     Soup.Message       msg,
                                     Soup.ClientContext client) {
        // Ignore if message isn't ours
        if (msg == this.msg)
            this.end (true, Soup.KnownStatusCode.NONE);
    }

    public void set_mime_type (string mime_type) {
        this.msg.response_headers.append ("Content-Type", mime_type);
    }

    public void push_data (void *data, size_t length) {
        this.msg.response_body.append (Soup.MemoryUse.COPY,
                                       data,
                                       length);

        this.server.unpause_message (this.msg);
    }

    public virtual void end (bool aborted, uint status) {
        if (status != Soup.KnownStatusCode.NONE) {
            this.msg.set_status (status);
        }

        this.ended ();
    }
}

public class Rygel.Seek : GLib.Object {
    public Format format { get; private set; }

    private int64 _start;
    public int64 start {
        get {
            return this._start;
        }
        set {
            this._start = value;
            this.length = stop - start + 1;
        }
    }

    private int64 _stop;
    public int64 stop {
        get {
            return this._stop;
        }
        set {
            this._stop = value;
            this.length = stop - start + 1;
        }
    }

    public int64 length { get; private set; }

    public Seek (Format format,
                 int64  start,
                 int64  stop) {
        this.format = format;
        this.start = start;
        this.stop = stop;
    }
}