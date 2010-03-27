shareddir = $(abs_top_builddir)/data

AM_CFLAGS = $(LIBGUPNP_CFLAGS) \
	    $(LIBGUPNP_AV_CFLAGS) \
	    $(LIBGSTREAMER_CFLAGS) \
	    $(GIO_CFLAGS) \
	    $(GEE_CFLAGS) \
	    $(UUID_CFLAGS) \
	    $(LIBSOUP_CFLAGS) \
	    $(LIBDBUS_GLIB_CFLAGS) \
	    -I$(top_srcdir) -DDATA_DIR='"$(shareddir)"' \
	    -include config.h

LDADD = $(LIBGUPNP_LIBS) \
	$(LIBGUPNP_AV_LIBS) \
	$(LIBGSTREAMER_LIBS) \
	$(GIO_LIBS) \
	$(GEE_LIBS) \
	$(UUID_LIBS) \
	$(LIBSOUP_LIBS) \
	$(LIBDBUS_GLIB_LIBS)

AM_VALAFLAGS = --disable-warnings --thread \
	       --pkg gupnp-1.0 --pkg gupnp-av-1.0 --pkg dbus-glib-1 \
               --pkg gconf-2.0 --pkg gstreamer-0.10 \
               --pkg gio-2.0 --pkg gee-1.0 -g

check_PROGRAMS = rygel-http-item-uri-test \
		 rygel-http-response-test \
		 rygel-live-response-test \
		 rygel-http-byte-seek-test
TESTS = $(check_PROGRAMS)

rygel_http_item_uri_test_SOURCES = rygel-http-item-uri-test.vala \
                                   rygel-http-item-uri.vala

rygel_http_response_test_SOURCES = rygel-http-response-test.vala \
				   rygel-http-response.vala \
				   rygel-state-machine.vala

rygel_live_response_test_SOURCES = rygel-live-response-test.vala \
				   rygel-live-response.vala \
                                   rygel-http-response_live-response.vala \
				   rygel-state-machine_live-response.vala \
				   rygel-http-seek_live-response.vala \
				   rygel-gst-utils.vala

rygel_http_byte_seek_test_SOURCES = rygel-http-byte-seek-test.vala \
				    rygel-http-byte-seek.vala \
				    rygel-http-seek.vala