import logging

ROOT_LOGGER_NAME = 'mamba'
FORMAT = '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
FILE_LEVEL = logging.DEBUG
CONSOLE_LEVEL = logging.INFO


def init(log_filename="log.log", debug=True):
	logging.root.name = ROOT_LOGGER_NAME
	logging.root.setLevel(logging.DEBUG)
	fh = logging.FileHandler(log_filename, mode='w')
	fh.setLevel(FILE_LEVEL)
	ch = logging.StreamHandler()
	if debug:
		ch.setLevel(FILE_LEVEL)
	else:	
		ch.setLevel(CONSOLE_LEVEL)
	formatter = logging.Formatter(FORMAT)
	fh.setFormatter(formatter)
	ch.setFormatter(formatter)
	logging.root.addHandler(fh)
	logging.root.addHandler(ch)
	logging.root.info("Logging to %s", log_filename)


def get_logger(name):
	return logging.root.getChild(name)


if __name__ == '__main__':
	l = get_logger()
	l.error("error!!!")
