SRCS = $(filter-out main.scm,$(foreach file,$(wildcard lib/*),$(notdir $(file))))
BUILD_DIR = build
OBJS = $(addprefix $(BUILD_DIR)/, $(SRCS:.scm=.o))

vpath %.scm lib

.PHONY: all directories clean

all: directories client server

directories: $(BUILD_DIR)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(BUILD_DIR)/%.o: %.scm
	csc -o $@ -c $<

client: $(BUILD_DIR)/client.o $(OBJS)
	csc -Wl,-lzmq $^ -o $@

server: $(BUILD_DIR)/server.o $(OBJS)
	csc -Wl,-lzmq $^ -o $@

clean:
	rm $(BUILD_DIR)/*.o
