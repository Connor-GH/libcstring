DC ?= gdc
WNOFLAGS = -Wno-unused-macros -Wno-reserved-identifier
ifeq ($(DC),gdc)
	_DFLAGS += -march=native -O3
	OF=-o
else
	OF=-of=
	_DFLAGS += -mcpu=native -O
endif

_DFLAGS += $(DFLAGS)
_LDFLAGS += $(LDFLAGS)
all: libcstring
libcstring: remove
	$(MAKE) remove
	$(DC) $(_DFLAGS) $(OF)$@ test.d $@.d $(_LDFLAGS)

remove:
	@rm -rf $(TARGET)
