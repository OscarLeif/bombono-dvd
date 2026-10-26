#include <mgui/_pc_.h>
#include <mgui/execution.h>
#include <mgui/ffviewer.h>
#include <mgui/prefs.h>
#include <mgui/stream_utils.h>
#include <mgui/win_utils.h>
#include <sstream>
#include <stdexcept>

static void Require(bool condition, const char* message)
{
    if( !condition )
        throw std::runtime_error(message);
}

int main(int argc, char** argv)
{
    try
    {
        Require(argc == 2, "Pass a test video filename");
        std::string video = argv[1];
        InitGtkmm(argc, argv);
        Require(MaxCPUWorkload() >= 1, "CPU detection failed");

        std::stringstream buffer;
        bin::stream binary(buffer);
        const unsigned long long large = (1ULL << 40) + 123;
        const std::string original("text\0with nul", 13);
        binary << large << original;
        unsigned long long restored = 0;
        std::string text;
        binary >> restored >> text;
        Require(restored == large && text == original, "64-bit binary stream round trip failed");

#ifdef _WIN32
        {
            Execution::ConsoleMode console;
            GPid process = Spawn(0, "exit /b 7", 0, true);
            Require(WaitForExit(process).IsCode(7), "Windows process exit status failed");
        }
        std::string output;
        ExitData exit = ExecuteAsync(0, "echo WINDOWS_SMOKE",
            [&output](const char* data, int size, bool) { output.append(data, size); });
        Require(exit.IsCode(0) && output.find("WINDOWS_SMOKE") != std::string::npos,
                "Windows asynchronous process output failed");
#endif

        FFViewer viewer;
        for( int i = 0; i != 2; ++i )
        {
            std::string error;
            Require(viewer.Open(video.c_str(), error), error.c_str());
            Require(bool(GetRawFrame(0.2, viewer)), "Video frame decoding failed");
            viewer.Close();
        }
        std::cout << "Windows smoke checks passed\n";
        return 0;
    }
    catch( const Glib::Error& error )
    {
        std::cerr << error.what() << '\n';
        return 1;
    }
    catch( const std::exception& error )
    {
        std::cerr << error.what() << '\n';
        return 1;
    }
}
