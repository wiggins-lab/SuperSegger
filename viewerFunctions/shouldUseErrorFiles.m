function value = shouldUseErrorFiles(FLAGS)
global canUseErr;
value = canUseErr == 1 && FLAGS.useSegs == 0;