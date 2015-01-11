SRCS = $(filter-out main.scm,$(foreach file,$(wildcard lib/*),$(notdir $(file))))
GAME = turing
BUILD_DIR = build
OBJS = $(addprefix $(BUILD_DIR)/, $(SRCS:.scm=.o))

vpath %.scm lib

.PHONY: all directories clean

all: directories $(GAME)

directories: $(BUILD_DIR)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(BUILD_DIR)/%.o: %.scm
	csc -o $@ -c $<

$(GAME): $(BUILD_DIR)/main.o $(OBJS)
	csc -Wl,-lzmq $^ -o $@

clean:
	rm $(BUILD_DIR)/*.o
