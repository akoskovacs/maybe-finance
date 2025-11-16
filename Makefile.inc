# Pass 'QUIET=n' to 'make' for verbose logging
QUIET=y

ifeq ($(QUIET),y)
	Q=@
else
	Q=
endif

