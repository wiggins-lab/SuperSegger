function FLAGS = fixFlags(FLAGS)
if ~isfield(FLAGS,'cell_flag')
    FLAGS.cell_flag  = 1;
end
if ~isfield(FLAGS,'m_flag')
    FLAGS.m_flag  = 0;
end
if ~isfield(FLAGS,'ID_flag')
    FLAGS.ID_flag  = 0;
end
if ~isfield(FLAGS,'T_flag')
    FLAGS.T_flag  = 0;
end
if ~isfield(FLAGS,'P_flag')
    FLAGS.P_flag  = 0;
end
if ~isfield(FLAGS,'Outline_flag')
    FLAGS.Outline_flag  = 1;
end
if ~isfield(FLAGS,'e_flag')
    FLAGS.e_flag  = 0;
end
if ~isfield(FLAGS,'f_flag')
    FLAGS.f_flag  = 0;
end
if ~isfield(FLAGS,'p_flag')
    FLAGS.p_flag  = 0;
end
if ~isfield(FLAGS,'s_flag')
    FLAGS.s_flag  = 1;
end
if ~isfield(FLAGS,'c_flag')
    FLAGS.c_flag  = 1;
end
if ~isfield(FLAGS,'P_val')
    FLAGS.P_val = 0.2;
end
if ~isfield(FLAGS,'filt')
    FLAGS.filt = 1;
end
if ~isfield(FLAGS,'lyse_flag')
    FLAGS.lyse_flag = 0;
end
if ~isfield(FLAGS,'regionScores')
    FLAGS.regionScores = 0;
end
if ~isfield(FLAGS,'useSegs')
    FLAGS.useSegs = 0;
end
if ~isfield(FLAGS,'showLinks')
    FLAGS.showLinks = 0;
end
if ~isfield(FLAGS,'showMothers')
    FLAGS.showMothers = 0;
end
if ~isfield(FLAGS,'showDaughters')
    FLAGS.showDaughters = 0;
end