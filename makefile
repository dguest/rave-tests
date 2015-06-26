# makefile for RAVE tests
# Author: Dan Guest (dguest@cern.ch)

# --- set dirs
BIN          := bin
SRC          := src
INC          := include
DICT         := dict
DEP          := $(BIN)

#  set search path
vpath %.o    $(BIN)
vpath %.cxx  $(SRC)
vpath %.hh   $(INC)
vpath %.h    $(INC)
vpath %Dict.h $(DICT)
vpath %Dict.cxx $(DICT)

# --- load in root config
RAVECFLAGS    := $(shell pkg-config rave --cflags)
RAVELIBS      := $(shell pkg-config rave --libs)
CLHEP_LDFLAGS := $(shell clhep-config --libs)
# ROOTLIBS      += -lTreePlayer   #required to read trees properly (?)
# ROOTLIBS      += -lTMVA         #don't know why this isn't loaded by default
# ROOTLIBS      += -lXMLParser    #don't know why this isn't loaded by default
# ROOTLIBS      += -lEG           #for TParticle


# --- set compiler and flags (roll c options and include paths together)
CXXFLAGS     := -O2 -Wall -fPIC -I$(INC) -g -std=c++11
COMPILER_NAME := $(notdir ${CXX})
ifeq ($(COMPILER_NAME), g++)
  LDFLAGS      := -Wl,-no-undefined
endif

# rootstuff
CXXFLAGS     += $(RAVECFLAGS)
LDFLAGS      += $(CLHEP_LDFLAGS)
LIBS         += $(RAVELIBS)

# dependency flags
DEPINCLUDE := -I$(INC) -I$(shell pkg-config rave --cflags)
DEPFLAGS    = -M -MP -MT $(BIN)/$*.o -MT $(DEP)/$*.d $(DEPINCLUDE)

# ---- define objects
TOBJ        :=
T_DICTS     := $(TOBJ:.o=Dict.o)
GEN_OBJ     :=
EXE_OBJ     := test.o

ALLDEPOBJ   := $(TOBJ) $(EXE_OBJ) $(GEN_OBJ)
ALLOBJ      := $(ALLDEPOBJ) $(T_DICTS)

OUTPUT    := test

all: $(OUTPUT)

$(OUTPUT): $(ALLOBJ:%=$(BIN)/%)
	@echo "linking $^ --> $@"
	@$(CXX) -o $@ $^ $(LIBS) $(LDFLAGS)

# --------------------------------------------------

# root dictionary generation
LINKDEF := LinkDef.h
$(DICT)/%Dict.cxx: %.h $(LINKDEF)
	@echo making dict $@
	@mkdir -p $(DICT)
	@rm -f $(DICT)/$*Dict.h $(DICT)/$*Dict.cxx
	@rootcint $@ -c $(INC)/$*.h $(INC)/$(LINKDEF)
	@sed -i 's,#include "$(INC)/\(.*\)",#include "\1",g' $(DICT)/$*Dict.h

$(BIN)/%Dict.o: $(DICT)/%Dict.cxx
	@mkdir -p $(BIN)
	@echo compiling dict $@
	@$(CXX) $(CXXFLAGS) $(RAVECFLAGS) -c $< -o $@

# compile rule
$(BIN)/%.o: %.cxx
	@echo compiling $<
	@mkdir -p $(BIN)
	@$(CXX) -c $(CXXFLAGS) $< -o $@

# use auto dependency generation

ifneq ($(MAKECMDGOALS),clean)
  ifneq ($(MAKECMDGOALS),rmdep)
    include $(ALLDEPOBJ:%.o=$(DEP)/%.d)
  endif
endif

$(DEP)/%.d: %.cxx
	@echo making dependencies for $<
	@mkdir -p $(DEP)
	@$(CXX) $(DEPFLAGS) $< -o $@

# clean
.PHONY : clean rmdep
CLEANLIST     = *~ *.o *.o~ *.d core
clean:
	rm -fr $(CLEANLIST) $(CLEANLIST:%=$(BIN)/%) $(CLEANLIST:%=$(DEP)/%)
	rm -fr $(BIN) $(OUTPUT) $(DICT) $(DEP)

rmdep:
	rm -f $(DEP)/*.d
