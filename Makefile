CC = g++
CFLAGS = -Wall -g

all: build

tema1.cpp: tema1.lex
	flex --outfile=$@ $<

build: tema1

tema1: tema1.o 
	$(CC) $(CFLAGS) -o $@ $^ -lfl

.PHONY: clean

run: build
	./tema1 $(arg)

clean:
	rm -f *.o *~ tema1.cpp tema1
