#include <iostream>
#include <cstdio>
#include <cstdint>
#include <chrono>
#include <cstdlib>
#include <iomanip>
#include <ctime>

extern "C" void load_ring(const char* string, const uint64_t strlen, const uint64_t iters) noexcept;
extern "C" const uint32_t dump(const char* string, uint32_t strlen) noexcept;
extern "C" const uint32_t falloc(const uint32_t mbytes) noexcept;
extern "C" const uint32_t threads() noexcept;

typedef long double fl64;
typedef float fl32;

namespace MAGIC_VALUES {
	inline const uint32_t FLOPSRATE_ITERATIONS = 1e9;
	inline const fl64 a = 1.234;
	inline const fl64 b = 5.678;
	inline const uint8_t LOADING_ITERATIONS = 5;
};

class GlobalError {
	private:
		const std::string error_message;
		const uint32_t error_status;
	public:
		GlobalError(const std::string& message, const uint32_t& status) : error_message{message}, error_status{status} {}
		
		const std::string what() const noexcept { return this->error_message; }
		const uint32_t stat() const noexcept { return this->error_status; }
};

inline const fl64 mflopsrate() noexcept {
	auto start = std::chrono::high_resolution_clock::now();
	fl64 dummy{};

	for (uint32_t i = 0; i < MAGIC_VALUES::FLOPSRATE_ITERATIONS; ++i) {
		dummy = MAGIC_VALUES::a * MAGIC_VALUES::b;		
	}

	auto end = std::chrono::high_resolution_clock::now();
	auto duration = std::chrono::duration_cast<std::chrono::nanoseconds>(end - start);

	return static_cast<fl64>(MAGIC_VALUES::FLOPSRATE_ITERATIONS) / duration.count() * 1000;
}

inline const std::pair<const std::string, const fl64> mflops_log() noexcept {
	const char* msg = "Counting of MFLOPS ";
  	const uint64_t ln = 19;
	const uint64_t iters = MAGIC_VALUES::LOADING_ITERATIONS;
	
	load_ring(msg, ln, iters);

	const fl64 mflops = mflopsrate();
	const std::string retstr = "MFLOPS : " + std::to_string(mflops);

	std::cout << '\r' << retstr << "       \n";

	return std::make_pair(retstr, mflops);
}

inline void fill_vmemo(char* const ptr, const uint64_t& size, char value) noexcept {
	for (uint64_t i = 0; i < size; ++i) {
		*(ptr + i) = value;
	}
}

inline const std::pair<const std::string, const uint32_t> mem_falloc(const uint32_t mbytes) {
	try {
		const uint32_t falloc_result = falloc(mbytes);
		std::cout << falloc_result;
		if (falloc_result) throw GlobalError("Couldn't allocate memory (something went wrong)", 1);
		std::cout << '\r';
		
		std::string retstr = std::to_string(mbytes << 20) + " BYTES (" + std::to_string(mbytes) + " MB) allocated in \"testdir/memory.bin\"";			
		std::cout << '\r' << retstr << "                 \n";
		return std::make_pair(retstr, mbytes);		
	} catch (const GlobalError& err) {
		if (err.stat() == 1) {
			std::cout << err.what() << '\n';
			return std::make_pair(err.what(), 2);
		}

		throw std::logic_error("Unknown error");
	}
}

struct valloc_s {
	std::string msg;
	char* mem_ptr;
	uint32_t mbytes;
};

inline const valloc_s mem_valloc(const uint32_t mbytes) {
		char* valloc_ptr = nullptr;
		const uint64_t valloc_bytes = mbytes << 20;
		
		std::cout << "Allocating of " << mbytes << " MB to RAM..." << std::flush; 
			
		valloc_ptr = new char[valloc_bytes];
		fill_vmemo(valloc_ptr, valloc_bytes, 0);
				
		const std::string dump_str = std::to_string(valloc_bytes) + " BYTES (" + std::to_string(mbytes) + " MB)  allocated in RAM";
			
		std::cout << '\r' << dump_str << "                  \n";
						
		return {dump_str, valloc_ptr, 953};	
}

inline const std::pair<const std::string, const uint32_t> log_threads() noexcept {
	try {
		const uint32_t result = threads();

		if (result == -1) throw std::logic_error("cannot parse logic cores");

		const std::string msg = "Threads (logic cores) : " + std::to_string(result);
		std::cout << msg << '\n';

		return std::make_pair(msg, result);
	} catch (const std::exception& err) {
		std::cout << err.what();
		return std::make_pair("err", 1);
	}
}

class TestContract {
	private:
		const char* standart = "FUTH-20";
		const char* own_address = "1fx00001";
		const char* creator_address = "0fx00001";
	public:
		TestContract() = default;
		TestContract(const TestContract& test_contract) = delete;
		~TestContract() = default;

	static const std::pair<const std::string, const fl64> dummyConnect() {
			const char* msg = "Connecting to FUTH-20.0fx00001 ";
			const uint32_t len = 31;			
			const uint32_t iters = 3;
			
			const auto start = std::chrono::high_resolution_clock::now();			

			load_ring(msg, len, iters);

			const auto end = std::chrono::high_resolution_clock::now();			
			const auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(end - start);
			const fl64 res = static_cast<fl64>(duration.count()) / 1000;
			std::string retstr = "Connection to FUTH-20.0fx00001 spent : " + std::to_string(res) + " sec";

			std::cout << '\r' << retstr << "                   \n";
			
			return std::make_pair(retstr, res);
		}
};

class TestUser {
	private: 
		fl64 anor{};
		uint32_t fallocated{};
		uint32_t vallocated{};
	public:
		TestUser() = default;
		TestUser(const TestUser& tuser) = delete;	
		~TestUser() = default;		

		const std::pair<const uint32_t, char*> calculateAnor() noexcept {
			try {
				std::cout << "|---> ANOR-parser 1.1 by Futhex Core. <---|\n\n";
				
				uint64_t falloc_mbytes{};
				uint64_t valloc_mbytes{};					

				std::cout << "Enter MBYTES value to allocate these in disk : ";
				std::cin >> falloc_mbytes;

				std::cout << "Enter MBYTES value to allocate these in RAM : ";
				std::cin >> valloc_mbytes;
				std::cout << '\n';

				if (!falloc_mbytes | !valloc_mbytes) throw std::invalid_argument("Cannot allocate 0 MB");

				fl64 current_anor{};
				std::string dump_msg = "Timestamp : " + std::to_string(std::time(nullptr)) + '\n';

				const std::pair<const std::string, const uint32_t> falloc_res = mem_falloc(falloc_mbytes);
				if (falloc_res.second <= 2) return (falloc_res.second == 1) ? std::make_pair(1, nullptr) : std::make_pair(2, nullptr);
				current_anor += falloc_res.second;
				this->fallocated = falloc_res.second;
				dump_msg += (falloc_res.first + '\n');

				const valloc_s valloc_res = mem_valloc(valloc_mbytes);
				this->vallocated = valloc_res.mbytes;
				dump_msg += (valloc_res.msg + '\n');
			
				const std::pair<const std::string, const fl64> mflops_res = mflops_log();
				current_anor += mflops_res.second;
				dump_msg += (mflops_res.first + '\n');

				const std::pair<const std::string, const fl64> connect_res = TestContract::dummyConnect();
				current_anor /= connect_res.second;
				dump_msg += (connect_res.first + '\n');

				const std::pair<const std::string, const uint32_t> threads_res = log_threads();
				if (threads_res.second == -1) return std::make_pair(4, nullptr);

				current_anor *= threads_res.second;
				dump_msg += (threads_res.first + '\n');
						
				this->anor = current_anor;

				const std::string anor_msg = "ANOR : " + std::to_string(this->anor);

				std::cout << anor_msg << "\n\nLogs dumped to \"testdir/logs.txt\"\n";
				dump_msg += (anor_msg + "\n\n");			

				const char* c_dump_msg = dump_msg.c_str();
	
				const uint32_t dump_status = dump(c_dump_msg, dump_msg.size());
				if (dump_status) throw std::runtime_error("dump error");
						
				return std::make_pair(0, valloc_res.mem_ptr);
			} catch (const std::exception& err) {
				std::cout << err.what();
				return std::make_pair(3, nullptr);
			}
	} 
		
	const fl64 getAnor() const noexcept { return this->anor; }
};
