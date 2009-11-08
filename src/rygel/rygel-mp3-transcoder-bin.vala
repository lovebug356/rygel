/*
 * Copyright (C) 2009 Nokia Corporation.
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

using Gst;

internal enum Rygel.MP3Layer {
    TWO = 1,
    THREE = 2
}

/**
 * A Gst.Bin derivative that implements transcoding of any type of media (using
 * decodebin2) to mpeg 1 layer 2 and 3 format.
 */
internal class Rygel.MP3TranscoderBin : Gst.Bin {
    private const string AUDIO_SRC_PAD = "audio-src-pad";
    private const string AUDIO_SINK_PAD = "audio-sink-pad";

    private dynamic Element audio_enc;

    public MP3TranscoderBin (MediaItem     item,
                             Element       src,
                             MP3Transcoder transcoder) throws Error {
        Element decodebin = new Rygel.DecoderBin ();

        this.audio_enc = transcoder.create_encoder (item,
                                                    AUDIO_SRC_PAD,
                                                    AUDIO_SINK_PAD);

        this.add_many (src, decodebin, this.audio_enc);
        src.link (decodebin);

        var src_pad = this.audio_enc.get_static_pad (AUDIO_SRC_PAD);
        var ghost = new GhostPad (null, src_pad);
        this.add_pad (ghost);

        decodebin.pad_added += this.decodebin_pad_added;
    }

    private void decodebin_pad_added (Element decodebin, Pad new_pad) {
        Pad enc_pad = this.audio_enc.get_pad (AUDIO_SINK_PAD);
        if (!new_pad.can_link (enc_pad)) {
            return;
        }

        if (new_pad.link (enc_pad) != PadLinkReturn.OK) {
            GstUtils.post_error (this,
                                 new LiveResponseError.LINK (
                                                "Failed to link pad %s to %s",
                                                new_pad.name,
                                                enc_pad.name));
            return;
        }
    }
}
