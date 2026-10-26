CC      = aarch64-linux-gnu-gcc
CFLAGS  = -O2 -Wall -I/usr/include/aarch64-linux-gnu -I/usr/include -D_REENTRANT
LDFLAGS = -L/usr/lib/aarch64-linux-gnu -lSDL2 -lm -ldl
APP     = GLProbe

all: $(APP)
$(APP): gles_probe.c
	$(CC) $(CFLAGS) $< -o $@ $(LDFLAGS)
	file $@

package: all
	@true
	rm -rf ../out/Apps/$(APP) && mkdir -p ../out/Apps/$(APP)
	cp $(APP) launch.sh config.json icon.png ../out/Apps/$(APP)/
	chmod +x ../out/Apps/$(APP)/launch.sh ../out/Apps/$(APP)/$(APP)
	@echo "Copia out/Apps/$(APP) a SDCARD/Apps/ (o Ports/ segun tu firmware)"
