# http://cython.org/
# http://wiki.cython.org/InstallingOnWindows
# http://conference.scipy.org/proceedings/SciPy2009/paper_1/full_text.pdf
# http://simula.no/research/sc/publications/Simula.SC.578/simula_pdf_file
# http://conference.scipy.org/proceedings/SciPy2009/paper_2/full_text.pdf
# http://stackoverflow.com/questions/6034390/compiling-with-cython-and-mingw-produces-gcc-error-unrecognized-command-line-o
import os
import numpy
import pyximport

if os.name == 'nt':
    if os.environ.has_key('CPATH'):
        os.environ['CPATH'] = os.environ['CPATH'] + numpy.get_include()
    else:
        os.environ['CPATH'] = numpy.get_include()

    # XXX: we're assuming that MinGW is installed in C:\MinGW (default)
    if os.environ.has_key('PATH'):
        os.environ['PATH'] = os.environ['PATH'] + ';C:\MinGW\bin'
    else:
        os.environ['PATH'] = 'C:\MinGW\bin'

    mingw_setup_args = { 'options': { 'build_ext': { 'compiler': 'mingw32' } } }
    pyximport.install(setup_args=mingw_setup_args)

elif os.name == 'posix':
    if os.environ.has_key('CFLAGS'):
        os.environ['CFLAGS'] = os.environ['CFLAGS'] + ' -I' + numpy.get_include()
    else:
        os.environ['CFLAGS'] = ' -I' + numpy.get_include()

    pyximport.install()