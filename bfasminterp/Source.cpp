#include <cassert>
#include <iostream>
#include <fstream>
#include <chrono>

using namespace std;
using namespace std::chrono;

const int mem_size = 30000;

enum class eOpcode : uint16_t {
	// common
	Loop,
	Return, 
	Right,
	Left,
	Add,
	Minus,
	
	// uncommon
	Print,
	Read,
	Invalid,

	End
};

struct instruction {
	eOpcode opcode;
	uint16_t value;
};

void run(const char * code, long code_size, bool bench);
extern "C" int interpret(instruction* instructions, size_t count, int8_t* mem);

extern "C" void printChar(char c) {
	cout << c; // literally
}

int main(int argc, char *argv[])
{
	if (argc == 1) {
		cout << "Please provide a source file name.\n";
		return 1;
	}

	bool bench = false;
	if (argc == 3 && argv[2][0] == 'b') {
		bench = true;
	}

	char* fileName = argv[1];
	ifstream fs;
	fs.open(fileName);

	if (fs.fail())
	{
		cerr << "Error: " << strerror(errno) << endl;
		return 1;
	}

	fs.seekg(0, fs.end);
	long code_size = fs.tellg();
	fs.seekg(0, fs.beg);

	char * code = new char[code_size + 1];
	code[code_size] = 0; // teminate NULL
	fs.read(code, code_size);
	fs.close();

	size_t loops = bench ? 50 : 1;

	auto t1 = high_resolution_clock::now();
	for (size_t i = 0; i < loops; i++)
	{
		run(code, code_size, bench);
	}
	auto t2 = high_resolution_clock::now();

	auto duration = duration_cast<nanoseconds>(t2 - t1).count();
	cout << "Execution time (ns): " << duration << endl;

	if (!bench)
		cin.get();
}

void run(const char * code, long code_size, bool bench)
{
	instruction instructions[10000];
	size_t instructions_count = 0;

	for (size_t ip = 0; ip < code_size;) {
		size_t tip = ip;
		char c = code[ip];
		eOpcode op = eOpcode::Invalid;
		switch (c) {
		case '+':
			op = eOpcode::Add;
			break;
		case '-':
			op = eOpcode::Minus;
			break;
		case '>':
			op = eOpcode::Right;
			break;
		case '<':
			op = eOpcode::Left;
			break;
		case '.':
			if (bench) {
				ip++;
				continue;
				break;
			}
			else {
				op = eOpcode::Print;
			}
			break;
		case ',':
			op = eOpcode::Read;
			break;
		case '[':
			op = eOpcode::Loop;
			break;
		case ']':
			op = eOpcode::Return;
			break;
		default:
			op = eOpcode::Invalid;
			ip++;
			continue;
			break;
		}

		instructions[instructions_count].opcode = op;

		if (op != eOpcode::Loop && op != eOpcode::Return && op != eOpcode::Print) {
			while (tip < code_size && code[tip] == c) {
				tip++;
			}
			instructions[instructions_count].value = tip - ip;
			ip = tip;
		}
		else {
			ip++;
		}

		instructions_count++;
	}

	instructions[instructions_count].opcode = eOpcode::End;

	for (size_t ip = 0; ip < instructions_count; ip++)
	{
		int brackets = 1;
		size_t tip = ip;
		switch (instructions[ip].opcode)
		{
		case eOpcode::Loop:
			while (tip < instructions_count) {
				tip++;
				if (instructions[tip].opcode == eOpcode::Return) brackets--;
				if (instructions[tip].opcode == eOpcode::Loop) brackets++;
				if (brackets == 0) {
					instructions[ip].value = tip - ip;
					break; // balanced
				}
			}
			break;
		case eOpcode::Return:
			while (tip > 0) {
				tip--;
				if (instructions[tip].opcode == eOpcode::Return) brackets++;
				if (instructions[tip].opcode == eOpcode::Loop) brackets--;
				if (brackets == 0) {
					instructions[ip].value = ip - tip + 1;
					break; // balanced
				}
			}
			break;
		default:
			break;
		}
	}

	int8_t mem[mem_size] = { 0 }; // memory

	interpret(instructions, instructions_count, mem);

	cout.flush();
}