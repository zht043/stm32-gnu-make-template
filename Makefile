#Target name
target = GMT

.DEFAULT_GOAL:=default
default: 
	make -j8 $(target).elf


#CubeMx-generated firmware directory
FDIR = Firmware

#build directory to store all intermediate object files for faster rebuilding 
BUILD = Build


#Extract variables from the CubeMX-generated Makefile
include $(FDIR)/Makefile
c_src = $(addprefix $(FDIR)/,$(sort $(C_SOURCES)))
c_inc = $(addprefix -I$(FDIR)/,$(sort $(C_INCLUDES:-I%=%)))
a_src = $(addprefix $(FDIR)/,$(sort $(ASM_SOURCES)))
a_inc = $(addprefix -I$(FDIR)/,$(sort $(ASM_INCLUDES:-I%=%)))
linkscript = $(FDIR)/$(LDSCRIPT)
DEFAULT_DEFINES = $(C_DEFS)

#User-defined sources & headers (for c or asm sources, use c_src+=<loc>/*.c)
SCRDIR = STM32CubeRobotics-Framework
cpp_inc = $(c_inc) \
-I$(SCRDIR)/Drivers/inc \
-I$(SCRDIR)/Modules/inc

cpp_src = \
$(wildcard *.cpp) \
$(wildcard $(SCRDIR)/Drivers/src/*.cpp) \
$(wildcard $(SCRDIR)/Modules/src/*.cpp)


#Compliers
compiler_path =
compiler_prefix = arm-none-eabi-
cc = $(compiler_path)$(compiler_prefix)gcc
cxx = $(compiler_path)$(compiler_prefix)g++
as = $(compiler_path)$(compiler_prefix)gcc -x assembler-with-cpp
cp = $(compiler_path)$(compiler_prefix)objcopy
sz = $(compiler_path)$(compiler_prefix)size


#########===================== Frequently modified flags ======================#########
###macros (#define) (append user defines here)
macros = $(DEFAULT_DEFINES) 

###Run time Library standards (Standard Lib(space-consuming!!!): nosys.specs, Nano Lib: nano.specs)
rtlib_std = -specs=nosys.specs

###Optimization Level (options: -O0, -O1, -O2, -O3, -Og)
opt = -O0

###debug(GDB) mode on(1) or off(any other value)
debug = 1
#########======================================================================#########

#Compiler Flags
mcu = -mcpu=cortex-m4 -mthumb -mfpu=fpv4-sp-d16 -mfloat-abi=hard
c_std = -std=gnu11
cpp_std = -std=gnu++14 


###Asembler flags
asflags = $(mcu) $(a_inc) $(opt) \
-Wall -fdata-sections -ffunction-sections -fstack-usage 

###C flags
cflags = $(mcu) $(c_std) $(macros) $(c_inc) $(opt) \
-Wall -fdata-sections -ffunction-sections -fstack-usage \
-MMD -MP -MF"$(@:%.o=%.d)"

###C++ flags
cppflags = $(mcu) $(cpp_std) $(macros) $(cpp_inc) $(opt) \
-Wall -fdata-sections -ffunction-sections -fstack-usage \
-MMD -MP -MF"$(@:%.o=%.d)" -fno-exceptions -fno-rtti \
-fno-threadsafe-statics -fno-use-cxa-atexit

ifeq ($(debug), 1)
cflags += -DDEBUG -g3 -gdwarf-2
cppflags += -DDEBUG -g3 -gdwarf-2
endif

###Linker Flags
libs = -lc -lm -lstdc++ -lsupc++
ldflags = $(mcu) $(rtlib_std) -T$(linkscript) \
-Wl,-Map=$(BUILD)/$(target).map,--cref \
-Wl,--gc-sections -static \
-Wl,--start-group $(libs) -Wl,--end-group


#Make Rules
objs = $(addprefix $(BUILD)/,$(notdir $(a_src:.s=.o)))
vpath %.s $(sort $(dir $(a_src)))

objs += $(addprefix $(BUILD)/,$(notdir $(c_src:.c=.o)))
vpath %.c $(sort $(dir $(c_src)))

objs += $(addprefix $(BUILD)/,$(notdir $(cpp_src:.cpp=.o)))
vpath %.cpp $(sort $(dir $(cpp_src)))

$(BUILD):
	mkdir $@

$(BUILD)/%.o: %.c Makefile | $(BUILD) 
	@$(cc) -c $(cflags) -Wa,-a,-ad,-alms=$(BUILD)/$(notdir $(<:.c=.lst)) $< -o $@
	@echo '$(cc) -c [.....] $(notdir $<) -o $(notdir $@)'

$(BUILD)/%.o: %.cpp Makefile | $(BUILD) 
	@$(cxx) -c $(cppflags) -Wa,-a,-ad,-alms=$(BUILD)/$(notdir $(<:.cpp=.lst)) $< -o $@
	@echo '$(cxx) -c [.....] $(notdir $<) -o $(notdir $@)'

$(BUILD)/%.o: %.s Makefile | $(BUILD)
	@$(as) -c $(asflags) $< -o $@
	@echo '$(as) -c [.....] $(notdir $<) -o $(notdir $@)'

$(target).elf: $(objs) Makefile
	@$(cxx) $(objs) $(ldflags) -o $@
	@echo '$(cxx) [...all objs...] [...ldflags...] -o $@'
	$(sz) $@

-include $(wildcard $(BUILD)/*.d)

#PHONY Targets
.PHONY: 
	default 
	Clean 
	echo-objs 
	echo-sources 
	echo-target
	echo-flags

#Clean
Clean:
	-rm -fR $(BUILD)
	-rm $(target).elf

#Print Info
echo-objs:
	@echo "$(objs)" | tr " " "\n"

echo-target:
	@echo "$(target)"

echo-flags:
	@echo "==================================================================="
	@echo "Assembly Flags:"
	@echo "$(asflags)" | fold -w 80
	@echo "==================================================================="	
	@echo "C Flags:"
	@echo "$(cflags)" | fold -w 80
	@echo "==================================================================="
	@echo "C++ Flags:"
	@echo "$(cppflags)" | fold -w 80
	@echo "==================================================================="	
	@echo "Linker Flags:"
	@echo "$(ldflags)" | fold -w 80
	@echo "==================================================================="	

echo-sources: 
	@echo "==================================================================="
	@echo "Link Scripts:"
	@echo "$(linkscript)" | tr " " "\n"
	@echo "==================================================================="
	@echo "Assembly Sources:"
	@echo "$(a_src)" | tr " " "\n"
	@echo "==================================================================="
	@echo "Assembly Includes:"
	@echo "$(a_inc)" | tr " " "\n"
	@echo "==================================================================="
	@echo "C Sources:"
	@echo "$(c_src)" | tr " " "\n"
	@echo "==================================================================="
	@echo "C Includes:"
	@echo "$(c_inc)" | tr " " "\n"
	@echo "==================================================================="
	@echo "C++ Sources:"
	@echo "$(cpp_src)" | tr " " "\n"
	@echo "==================================================================="
	@echo "C++ Includes:"
	@echo "$(cpp_inc)" | tr " " "\n"
	@echo "==================================================================="

