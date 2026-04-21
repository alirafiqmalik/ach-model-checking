# Merge model fragments into $(OUTPUT); optional verify with nuXmv.

NUXMV      ?= ./tools/nuXmv
OUTPUT     := _main_model.smv
MERGE      := ./tools/merge_smv.sh

MODEL_PARTS := \
	models/00_types_channels.smv \
	models/10_originator.smv \
	models/20_odfi.smv \
	models/30_ach_operator.smv \
	models/40_rdfi.smv \
	models/50_receiver.smv \
	models/60_global_constraints.smv \
	models/99_main.smv

.PHONY: all merge verify check-merge clean smoke test

all: merge check-merge

$(OUTPUT): $(MODEL_PARTS) $(MERGE)
	$(MERGE) $(OUTPUT) $(MODEL_PARTS)

merge: $(OUTPUT)

verify: $(OUTPUT)
	$(NUXMV) -v 4 $(OUTPUT)

check-merge: $(OUTPUT)
	cat $(MODEL_PARTS) | diff -u - $(OUTPUT)

clean:
	rm -f $(OUTPUT) tests/fixtures/minimal/_merged_test.smv

# Fast checks: parse + flatten full merged model; merge+tiny-model nuXmv batch.
smoke: $(OUTPUT)
	printf '%s\n' 'read_model -i $(OUTPUT)' 'flatten_hierarchy' 'quit' | $(NUXMV) -int

test:
	./tools/test_minimal.sh
