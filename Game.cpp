#include <windows.h>
#include <sstream>
int main(int argc,char** argv) {
	char rtp[256] = { 0 };
	GetPrivateProfileString("Game", "RTP", "", rtp, 256-1, "./devGame.ini");
	std::stringstream ss;
	int error = 0;
	if (*rtp) {
		char* path = new char[65536];
		DWORD size=65535;
		DWORD type = REG_SZ;
		if (error = RegGetValue(HKEY_LOCAL_MACHINE, "SOFTWARE\\Enterbrain\\RGSS\\RTP", rtp, RRF_RT_REG_SZ, &type, path, &size)) {
			if (error != ERROR_FILE_NOT_FOUND) {
				ss << "¶ÁÈ¡×¢²á±íÊ§°Ü:" << error;
			}
			else {
				error = 0;
			}
		}
		else {
			HKEY hk = 0;
			if (error = RegCreateKeyEx(HKEY_LOCAL_MACHINE, "SOFTWARE\\Enterbrain\\RGSS3\\RTP", 0, NULL, REG_OPTION_NON_VOLATILE, KEY_WRITE, NULL, &hk, NULL)) {
				ss << "´ò¿ª×¢²á±íÊ§°Ü:" << error;
			}else if (error = RegSetValueEx(hk, rtp, 0, REG_SZ, (BYTE*)path, size)) {
				ss << "Ð´Èë×¢²á±íÊ§°Ü:" << error;
			}
		}
		delete[] path;
	}
	if (error) { 
		MessageBox(NULL,ss.str().c_str(), NULL, NULL);
		return 0;
	}
	ss.str("");
	ss << "devGame.exe";
	for (int i = 1; i < argc; i++) {
		ss << " \"" << argv[i] << "\"";
	}
	return system(ss.str().c_str());
}