/*
 * Copyright (C) 2009 Thijs Vermeir
 *
 * Author: Thijs Vermeir <thijsvermeir@gmail.com>
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
using Gee;

internal class Rygel.DecoderBin : Gst.Bin {
    private const string DECODE_BIN = "decodebin2";
    private const string SINK_PAD= "sink";

    private dynamic Element decodebin;
    private dynamic Element subtitlebin;

    public DecoderBin (string? subtitle_uri = null) throws GLib.Error {
        decodebin = GstUtils.create_element (DECODE_BIN, DECODE_BIN);
        this.add (decodebin);

        /* connect the signals */
        decodebin.pad_added += this.pad_added_cb;

        /* create the ghost sink */
        var pad = decodebin.get_static_pad (SINK_PAD);
        var ghost = new GhostPad (null, pad);
        this.add_pad (ghost);

        var config = MetaConfig.get_default ();
        if (config.get_enable_subtitles () && subtitle_uri != null) {
          debug (@"add subtitle uri: $subtitle_uri");
          subtitlebin = Gst.parse_bin_from_description (@"filesrc location=$subtitle_uri ! subparse ! textoverlay", true);
          this.add (subtitlebin);
        }
    }

    private void add_ghost_for_pad (Pad new_pad) {
        var ghost = new GhostPad (null, new_pad);
        ghost.set_active (true);
        add_pad (ghost);
    }

    private void pad_added_cb (Element decoder, Pad new_pad) {
        debug ("adding pad %s", new_pad.get_name ());
        if (subtitlebin != null) {
          var sinkpad = subtitlebin.get_static_pad ("sink");
          if (!sinkpad.is_linked () && new_pad.link (sinkpad) == Gst.PadLinkReturn.OK) {
              add_ghost_for_pad (subtitlebin.get_static_pad ("src"));
          } else {
              add_ghost_for_pad (sinkpad);
          }
        } else {
          add_ghost_for_pad (new_pad);
        }
    }
}
