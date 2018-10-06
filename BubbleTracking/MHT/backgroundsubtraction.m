function [ foreground ] = backgroundsubtraction( avi )

frames = {avi.cdata};

% First frame is background:
background = frames{1};

foreground = {};

for i=1:length(frames)
    foreground{i} = abs(frames{i}-background);
end
return
