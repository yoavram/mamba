import logging

FORMAT = '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
FILE_LEVEL = logging.DEBUG
CONSOLE_LEVEL = logging.INFO

def get_logger(log_filename="log.log", debug=True):
	logger = logging.getLogger('mamba')
	logger.setLevel(logging.DEBUG)
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
	logger.addHandler(fh)
	logger.addHandler(ch)
	logger.info("Logging to %s", log_filename)
	return logger


if __name__ == '__main__':
	l = get_logger()
	l.error("error!!!")
