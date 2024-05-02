DC ?= gdc
WNOFLAGS = -Wno-unused-macros -Wno-reserved-identifier
_DFLAGS ?= $(DFLAGS)
_LDFLAGS ?= $(LDFLAGS)
ifeq ($(DC),gdc)
	_DFLAGS += -march=native -O3 -frelease
	OF=-o
else
	OF=-of=
	_DFLAGS += -mcpu=native -O -release
endif

all: libcstring
libcstring: remove
	$(MAKE) remove
	$(DC) $(_DFLAGS) $(OF)$@ $@.d $(_LDFLAGS)

remove:
	@rm -rf $(TARGET)
