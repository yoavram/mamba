import logging

ROOT_LOGGER_NAME = 'mamba'
FORMAT = '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
FILE_LEVEL = logging.DEBUG
CONSOLE_LEVEL = logging.INFO


def init(log_filename="tmp.log", debug=True):
	logging.root.name = ROOT_LOGGER_NAME
	logging.root.setLevel(logging.DEBUG)

	formatter = logging.Formatter(FORMAT)

	# console 
	ch = logging.StreamHandler()
	if debug:
		ch.setLevel(FILE_LEVEL)
	else:	
		ch.setLevel(CONSOLE_LEVEL)		
	ch.setFormatter(formatter)
	logging.root.addHandler(ch)

	# file 
	if isinstance(log_filename, str) and len(log_filename) > 0:
		fh = logging.FileHandler(log_filename, mode='w')
		fh.setLevel(FILE_LEVEL)
		fh.setFormatter(formatter)
		logging.root.addHandler(fh)
		logging.root.info("Logging to %s", log_filename)


def get_logger(name):
	return logging.root.getChild(name)


if __name__ == '__main__':
	init()
	l = get_logger('test')
	l.error("error!!!")
