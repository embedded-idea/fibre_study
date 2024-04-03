######################################
# target
######################################
TARGET = fibre_min

######################################
# building variables
######################################
# debug build?
DEBUG = 1

# optimization
OPT = -Og

#######################################
# paths
#######################################
# Build path
BUILD_DIR = build

######################################
# source
######################################
# C sources
C_SOURCES_FIBRE_CPP = \
fibre_cpp/channel_discoverer.cpp \
fibre_cpp/endpoint_connection.cpp \
fibre_cpp/func_utils.cpp \
fibre_cpp/legacy_object_server.cpp \
fibre_cpp/multiplexer.cpp \
fibre_cpp/connection.cpp \
fibre_cpp/fibre.cpp \
fibre_cpp/legacy_object_client.cpp \
fibre_cpp/legacy_protocol.cpp \
fibre_cpp/platform_support/can_adapter.cpp \
fibre_cpp/platform_support/posix_socket.cpp \
fibre_cpp/platform_support/usb_host_adapter.cpp \
fibre_cpp/platform_support/epoll_event_loop.cpp \
fibre_cpp/platform_support/posix_tcp_backend.cpp \
fibre_cpp/platform_support/webusb_backend.cpp \
fibre_cpp/platform_support/libusb_backend.cpp \
fibre_cpp/platform_support/socket_can.cpp

#autogen
C_SOURCES_AUTOGEN = \
autogen/endpoints.cpp \
autogen/static_exports.cpp

# test sources
C_SOURCES_TEST = \
src/test_node.cpp

C_SOURCES = $(C_SOURCES_FIBRE_CPP) \
$(C_SOURCES_TEST) \
$(C_SOURCES_AUTOGEN)

#######################################
# binaries
#######################################
#PREFIX = arm-none-eabi-
PREFIX = 

#try to get a correct python command to run all python scripts for me is python3 -B
ifeq ($(shell python -c "import sys; print(sys.version_info.major)"), 3)
	PY_CMD := python -B
else
	PY_CMD := python3 -B
endif

# The gcc compiler bin path can be either defined in make command via GCC_PATH variable (> make GCC_PATH=xxx)
# either it can be added to the PATH environment variable.
ifdef GCC_PATH
CXX = $(GCC_PATH)/$(PREFIX)g++ -std=c++17 -Wno-register
CC = $(GCC_PATH)/$(PREFIX)gcc -std=c99
AS = $(GCC_PATH)/$(PREFIX)gcc -x assembler-with-cpp
CP = $(GCC_PATH)/$(PREFIX)objcopy
SZ = $(GCC_PATH)/$(PREFIX)size
else
CXX = $(PREFIX)g++ -std=c++17 -Wno-register
CC = $(PREFIX)gcc -std=c99
AS = $(PREFIX)gcc -x assembler-with-cpp
CP = $(PREFIX)objcopy
SZ = $(PREFIX)size
endif
HEX = $(CP) -O ihex
BIN = $(CP) -O binary -S
 
#######################################
# CFLAGS
#######################################
# C defines
C_DEFS =  \
-DSTANDALONE_NODE

# C includes
C_INCLUDES_FIBRE = \
-Ifibre_cpp \
-Ifibre_cpp/include \
-Ifibre_cpp/include/fibre \
-Ifibre_cpp/platform_support 

C_INCLUDES_AUTOGEN = \
-Iautogen

C_INCLUDES_TEST = \
-Isrc


C_INCLUDES = -I./ \
$(C_INCLUDES_FIBRE) \
$(C_INCLUDES_AUTOGEN) \
$(C_INCLUDES_TEST)

# compile gcc flags
CFLAGS += $(C_DEFS) $(C_INCLUDES) $(OPT)


ifeq ($(DEBUG), 1)
CFLAGS += -g -gdwarf-2
endif


# Generate dependency information
CFLAGS += -MMD -MP -MF"$(@:%.o=%.d)"


#######################################
# LDFLAGS
#######################################
# libraries
LIBS = -lusb-1.0 -lanl -lpthread
LIBDIR = 

LDFLAGS = $(LIBDIR) $(LIBS) -Wl,-Map=$(BUILD_DIR)/$(TARGET).map,--cref -Wl,--gc-sections

# default action: build all
all: AUTOHEADERS $(BUILD_DIR)/$(TARGET).elf $(BUILD_DIR)/$(TARGET).hex $(BUILD_DIR)/$(TARGET).bin TESTBIN_HEX_ASM

AUTOHEADERS:
	@mkdir -p autogen
	@$(PY_CMD) ./tools/interface_generator.py --definitions test-interface.yaml --template fibre_cpp/static_exports_template.j2 --output autogen/static_exports.cpp
	@$(PY_CMD) ./tools/interface_generator.py --definitions test-interface.yaml --template fibre_cpp/interfaces_template.j2 --output autogen/interfaces.hpp
	@$(PY_CMD) ./tools/interface_generator.py --definitions test-interface.yaml --template fibre_cpp/legacy_endpoints_template.j2 --output autogen/endpoints.cpp

#######################################
# build the application
#######################################
# list of objects
OBJECTS_C = $(filter %.c,$(C_SOURCES))
OBJECTS = $(addprefix $(BUILD_DIR)/,$(notdir $(OBJECTS_C:.c=.o)))
vpath %.c $(sort $(dir $(C_SOURCES)))

OBJECTS_CXX = $(filter %.cpp,$(C_SOURCES))
OBJECTS += $(addprefix $(BUILD_DIR)/__,$(notdir $(OBJECTS_CXX:.cpp=.o)))
vpath %.cpp $(sort $(dir $(C_SOURCES)))

$(BUILD_DIR)/%.o: %.c Makefile | $(BUILD_DIR)
	@echo "ccccccccccccccccccccccccccccc"
	$(CC) -c $(CFLAGS) -Wa,-a,-ad,-alms=$(BUILD_DIR)/$(notdir $(<:.c=.lst)) $< -o $@

$(BUILD_DIR)/__%.o: %.cpp Makefile | $(BUILD_DIR) 
	@echo "c++++++++++++++++++++++++++++"
	$(CXX) -c $(CFLAGS) -Wa,-a,-ad,-alms=$(BUILD_DIR)/$(notdir $(<:.cpp=.lst)) $< -o $@


$(BUILD_DIR)/$(TARGET).elf: $(OBJECTS) Makefile
	$(CXX) $(OBJECTS) $(LDFLAGS) -o $@
	$(SZ) $@

$(BUILD_DIR)/%.hex: $(BUILD_DIR)/%.elf | $(BUILD_DIR)
	$(HEX) $< $@
	
$(BUILD_DIR)/%.bin: $(BUILD_DIR)/%.elf | $(BUILD_DIR)
	$(BIN) $< $@	
	
$(BUILD_DIR):
	mkdir $@	

TESTBIN_HEX_ASM: $(BUILD_DIR)/$(TARGET).elf
#display the size
	size $(BUILD_DIR)/$(TARGET).elf
#create *.hex and *.bin output formats
	objcopy -O ihex $(BUILD_DIR)/$(TARGET).elf $(BUILD_DIR)/$(TARGET).hex
	objcopy -O binary -S $(BUILD_DIR)/$(TARGET).elf $(BUILD_DIR)/$(TARGET).bin
	objdump $(BUILD_DIR)/$(TARGET).elf -dSC > $(BUILD_DIR)/$(TARGET).asm
	
#######################################
# clean up
#######################################
clean:
	-rm -fR $(BUILD_DIR) autogen
  
#######################################
# dependencies
#######################################
-include $(wildcard $(BUILD_DIR)/*.d)

# *** EOF ***
