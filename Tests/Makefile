CC=clang # or gcc

# Trick to get current dir: http://stackoverflow.com/questions/322936/common-gnu-makefile-directory-path
TESTS_DIR:= $(dir $(lastword $(MAKEFILE_LIST)))
PROJECT_DIR:= $(TESTS_DIR)/..

FRAMEWORKS_PATH:= -F/Applications/Xcode.app/Contents/Developer/Library/Frameworks
FRAMEWORKS:= -framework Foundation -framework SenTestingKit
LIBRARIES:= -lobjc
INCLUDE_PATHS:= -I$(PROJECT_DIR)/SACompositeOperations\
                -I$(TESTS_DIR)/TestHelpers

SOURCE_SA = $(wildcard $(PROJECT_DIR)/SACompositeOperations/*.m)
					
SOURCE_TEST_SUITE = $(wildcard $(TESTS_DIR)/Tests/*.m)

SOURCE_TESTS = $(TESTS_DIR)/TestHelpers/TestHelpers.m\
			         octest.m


CFLAGS=-Wall -Werror -fobjc-arc -fobjc-exceptions -fexceptions -fdiagnostics-show-option -fcolor-diagnostics -g -v $(SOURCE_SA) $(SOURCE_TEST_SUITE) $(SOURCE_TESTS)

LDFLAGS=$(LIBRARIES) $(FRAMEWORKS)
OUT=-o octest

all:
	    $(CC) $(FRAMEWORKS_PATH) $(CFLAGS) $(INCLUDE_PATHS) $(LDFLAGS) $(OUT)
