CC=clang # or gcc

find-recursive = \
  $(wildcard $1/$2) \
  $(foreach f,$(wildcard $1/*/.),\
  $(call find-recursive,$(patsubst %/.,%,$f),$2))

# Trick to get current dir: http://stackoverflow.com/questions/322936/common-gnu-makefile-directory-path
TESTS_DIR:= $(dir $(lastword $(MAKEFILE_LIST)))
PROJECT_DIR:= $(TESTS_DIR)/..

FRAMEWORKS_PATH:= -F/Applications/Xcode.app/Contents/Developer/Library/Frameworks
FRAMEWORKS:= -framework Foundation -framework SenTestingKit
LIBRARIES:= -lobjc

COMPOSITE_OPERATIONS_INCLUDE_PATHS = $(foreach directory, $(sort $(dir $(call find-recursive,$(PROJECT_DIR)/CompositeOperations,*))), \
    -I$(directory) \
  )

KIWI_INCLUDE_PATHS = $(foreach directory, $(sort $(dir $(call find-recursive,$(shell pwd)/Kiwi,*))), \
    -I$(directory) \
  )

INCLUDE_PATHS:=  $(COMPOSITE_OPERATIONS_INCLUDE_PATHS) \
                -I$(TESTS_DIR)/TestHelpers \
                 $(KIWI_INCLUDE_PATHS)

SOURCE_COMPOSITE_OPERATIONS = $(call find-recursive,$(PROJECT_DIR)/CompositeOperations,*.m)
					
SOURCE_TEST_SUITE = $(wildcard $(TESTS_DIR)/Tests/*.m)

SOURCE_TESTS = $(TESTS_DIR)/TestHelpers/TestHelpers.m \
							 $(call find-recursive,$(shell pwd)/Kiwi,*.m) \
			         octest.m


CFLAGS=-Wall -Werror -fobjc-arc -fobjc-exceptions -fexceptions -fdiagnostics-show-option -fcolor-diagnostics -g $(SOURCE_COMPOSITE_OPERATIONS) $(SOURCE_TEST_SUITE) $(SOURCE_TESTS)

LDFLAGS=$(LIBRARIES) $(FRAMEWORKS)
OUT=-o octest

test: compile octest

.PHONY:octest
octest:
		export DYLD_FRAMEWORK_PATH=/Applications/Xcode.app/Contents/Developer/Library/Frameworks; ./octest 2>&1 | awk -f "octest.awk"

compile:
		$(CC) $(FRAMEWORKS_PATH) $(CFLAGS) $(INCLUDE_PATHS) $(LDFLAGS) $(OUT)

