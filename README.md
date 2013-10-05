## pcp
another command-line file copy script with other stuff

---


1. ##### REQUIREMENTS
	
	This software was developed and tested with Perl v5.12.4 on Mac OS X 10.8.4, but any version of Perl 5 will work.
	
	The following Perl modules are required:
	
	- Getopt::Long
	- Pod::Usage
	- File::Spec
	- File::Path
	- File::Find
	- Time::HiRes
	
	And the following are optional:
	
	- POSIX
	- Term::ReadKey
	- Benchmark
	
	All of these packages are either included with Perl 5 or available for free from CPAN at <http://www.cpan.org>.


2. ##### INSTALLATION
	
	No installation is necessary. But for convenience, enable execute permissions and copy the script to an executable path directory:
	
	```
	chmod +x pcp
	cp pcp /usr/local/bin
	```
	
3. ##### USAGE
	
	To view the built-in POD-generated man page:
	
	```
	pcp --manpage
	```

4. ##### CONTACT
	
	e-mail: <andrew@ardnew.com>
