all:	compile gather
compile:
	$(MAKE) -C code/morph
	$(MAKE) -C code/syntan
	$(MAKE) -C code/transfer
	$(MAKE) -C code/ranker
gather:
	cp code/morph/morph_cz .
	cp code/syntan/syntan .
	cp code/transfer/transfer .
	cp code/ranker/ranker .
clean:
	rm morph_cz syntan transfer ranker
test:
	./morph_cz cz data/morphology_cz.txt test_example |./syntan data/gram_cz_shallow.txt data/gram_postproc_cz.txt | ./transfer czsk data/bilingual_czsk.txt data/morphology_sk.txt | ./ranker data/ranker_data_sk.txt
