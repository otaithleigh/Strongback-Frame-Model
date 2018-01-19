% StrongbackFrameTest.m
% Tester script for the StrongbackFrameModel
%
% Units: kip, in, sec

import SteelDesign.*

frame = StrongbackFrameModel;

frame.g             = 386;      % in./s^2
frame.units.force   = 'kip';
frame.units.length  = 'in.';
frame.units.time    = 'sec';

frame.nStories      = 4;                    % Number of stories
frame.storyHeight   = [12, 12, 12, 12]*12;  % Story heights (ft --> in.)
frame.nBays         = 3;                    % Number of bays
frame.bayWidth      = 24*12;                  % Width of bays (ft --> in.)
frame.nJoists       = 2;                    % Number of joists per bay

frame.bracePos      = 0.5;
frame.nBraceEle     = 4;
frame.nColumnEle    = 2;
frame.nBeamEle      = 2;

frame.deadLoad      = [ 60, 60, 60, 10 ]/(144*1000);   % psf --> ksi
frame.liveLoad      = [ 0, 0, 0, 0 ];

frame.includeResidualStresses = true;

%% Section definitions
%------------------------------------------------------------------------------%
t = SteelSection.readShapesTable('US');

frame.LeftColumns = {
    FrameMember(frame, SteelSection('W14x68', 'US', t), 1, 'column')
    FrameMember(frame, SteelSection('W14x68', 'US', t), 2, 'column')
    FrameMember(frame, SteelSection('W14x68', 'US', t), 3, 'column')
    FrameMember(frame, SteelSection('W14x68', 'US', t), 4, 'column')
};

frame.RightColumns = {
    FrameMember(frame, SteelSection('W14x68', 'US', t), 1, 'column')
    FrameMember(frame, SteelSection('W14x68', 'US', t), 2, 'column')
    FrameMember(frame, SteelSection('W14x68', 'US', t), 3, 'column')
    FrameMember(frame, SteelSection('W14x68', 'US', t), 4, 'column')
};

frame.FrameBeams = {
    FrameMember(frame, SteelSection('W24x207', 'US', t), 1, 'beam')
    FrameMember(frame, SteelSection('W24x207', 'US', t), 2, 'beam')
    FrameMember(frame, SteelSection('W24x207', 'US', t), 3, 'beam')
    FrameMember(frame, SteelSection('W14x68', 'US', t), 4, 'beam')
};

frame.LeftBraces = {
    FrameMember(frame, SteelSection('HSS4-1/2x4-1/2x3/8', 'US', t), 1, 'brace')
    FrameMember(frame, SteelSection('HSS4-1/2x4-1/2x5/16', 'US', t), 2, 'brace')
    FrameMember(frame, SteelSection('HSS4-1/2x4-1/2x5/16', 'US', t), 3, 'brace')
    FrameMember(frame, SteelSection('HSS3x3x1/4', 'US', t), 4, 'brace')
};

frame.TieBraces = {
    ''
    FrameMember(frame, SteelSection('HSS7x7x1/2', 'US', t), 2, 'tie')
    FrameMember(frame, SteelSection('HSS6x6x1/2', 'US', t), 3, 'tie')
    ''
};

frame.RightBraces = {
    FrameMember(frame, SteelSection('HSS7x7x1/2', 'US', t), 1, 'sback')
    FrameMember(frame, SteelSection('HSS7x7x1/2', 'US', t), 2, 'sback')
    FrameMember(frame, SteelSection('HSS7x7x1/2', 'US', t), 3, 'sback')
    FrameMember(frame, SteelSection('HSS4x4x1/2', 'US', t), 4, 'sback')
};

frame.LeaningColumns = {
    FrameMember(frame, SteelSection('W14x132', 'US', t), 1, 'column')
    FrameMember(frame, SteelSection('W14x132', 'US', t), 2, 'column')
    FrameMember(frame, SteelSection('W14x132', 'US', t), 3, 'column')
    FrameMember(frame, SteelSection('W14x132', 'US', t), 4, 'column')
};

frame.LeaningBeams = {
    FrameMember(frame, SteelSection('W14x68', 'US', t), 1, 'beam')
    FrameMember(frame, SteelSection('W14x68', 'US', t), 2, 'beam')
    FrameMember(frame, SteelSection('W14x68', 'US', t), 3, 'beam')
    FrameMember(frame, SteelSection('W14x68', 'US', t), 4, 'beam')
};

frame.designGussetPlates();


% %% Write stuff
% %------------------------------------------------------------------------------%
filename = frame.scratchFile('strongback_scbf_2d_input.tcl');
fid = fopen(filename, 'w');

frame.constructBuilding(fid)
frame.applyGravityLoads(fid)

fclose(fid);
