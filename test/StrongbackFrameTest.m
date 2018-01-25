% StrongbackFrameTest.m
% Tester script for the StrongbackFrameModel
%
% Units: kip, in, sec

clear('frame', 'pushover', 'rh')

import SteelDesign.*

frame = StrongbackFrameModel;

frame.g             = 386;      % in./s^2
frame.units.force   = 'kip';
frame.units.length  = 'in.';
frame.units.time    = 'sec';

frame.nStories      = 4;                    % Number of stories
frame.storyHeight   = [12, 12, 12, 12]*12;  % Story heights (ft --> in.)
frame.nBays         = 3;                    % Number of bays
frame.bayWidth      = 24*12;                % Width of bays (ft --> in.)
frame.bracePos      = 0.5;                  % Position along beam where braces connect
frame.nJoists       = 2;                    % Number of joists per bay


frame.deadLoad      = [ 60, 60, 60, 10 ]/(144*1000);   % psf --> ksi
frame.liveLoad      = [ 0, 0, 0, 0 ];


%% Analysis options
%------------------------------------------------------------------------------%
% General
frame.echoOpenSeesOutput        = false;
frame.deleteFilesAfterAnalysis  = false;

% Elements
frame.transfType = 'Corotational';  % Geometric transformation for all elements
frame.nIntPoints = 4;               % Number of integration points per element
frame.nFibers    = 20;              % Number of fibers per section
frame.nBraceEle  = 8;               % Number of elements per brace member
frame.nColumnEle = 8;               % Number of elements per column member
frame.nBeamEle   = 4;               % Number of elements per half-beam member

% Materials
frame.rigidE                    = 10e9;     % Elastic modulus of "rigid" elements
frame.includeResidualStresses   = true;     % Select whether to include residual stresses in material models
frame.GussetPlateModel          = 'spring'; % Select how to model gusset plate connections

% Pushover
frame.optionsPushover.stepSize          = [1e-2, 1e-3, 1e-5, 1e-7];
frame.optionsPushover.maxDrift          = 24.0; % in.
frame.optionsPushover.controlStory      = 'roof';
frame.optionsPushover.test.tolerance    = [1e-5, 1e-4, 1e-3];
frame.optionsPushover.test.iterations   = 30;
frame.optionsPushover.algorithm.type    = {'KrylovNewton', 'SecantNewton', 'BFGS'};

% Response history
gm_mat = '/home/petertalley/Dropbox/Research/Strongback-Frame-Model/test/ground_motions.mat';
gmIndex = 1;
SF = 1.3;

frame.optionsResponseHistory.test.tolerance  = [1e-5, 1e-4, 1e-3];
frame.optionsResponseHistory.test.iterations = 20;
frame.optionsResponseHistory.algorithm.type  = {'KrylovNewton', 'SecantNewton', 'BFGS'};


%% Section definitions
%------------------------------------------------------------------------------%
t = SteelSection.readShapesTable('US');

frame.LeftColumns = {
    FrameMember(frame, SteelSection('W14x82', 'US', t), 1, 'column')
    FrameMember(frame, SteelSection('W14x82', 'US', t), 2, 'column')
    FrameMember(frame, SteelSection('W14x68', 'US', t), 3, 'column')
    FrameMember(frame, SteelSection('W14x68', 'US', t), 4, 'column')
};

frame.RightColumns = {
    FrameMember(frame, SteelSection('W14x82', 'US', t), 1, 'column')
    FrameMember(frame, SteelSection('W14x82', 'US', t), 2, 'column')
    FrameMember(frame, SteelSection('W14x68', 'US', t), 3, 'column')
    FrameMember(frame, SteelSection('W14x68', 'US', t), 4, 'column')
};

frame.FrameBeams = {
    FrameMember(frame, SteelSection('W24x335', 'US', t), 1, 'beam')
    FrameMember(frame, SteelSection('W18x192', 'US', t), 2, 'beam')
    FrameMember(frame, SteelSection('W18x192', 'US', t), 3, 'beam')
    FrameMember(frame, SteelSection('W14x68', 'US', t), 4, 'beam')
};

frame.LeftBraces = {
    FrameMember(frame, SteelSection('HSS4-1/2x4-1/2x5/16', 'US', t), 1, 'brace')
    FrameMember(frame, SteelSection('HSS4-1/2x4-1/2x5/16', 'US', t), 2, 'brace')
    FrameMember(frame, SteelSection('HSS4x4x5/16', 'US', t), 3, 'brace')
    FrameMember(frame, SteelSection('HSS3x3x1/4', 'US', t), 4, 'brace')
};

frame.TieBraces = {
    ''
    FrameMember(frame, SteelSection('HSS5x5x5/16', 'US', t), 2, 'tie')
    FrameMember(frame, SteelSection('HSS5x5x1/2', 'US', t), 3, 'tie')
    ''
};

frame.RightBraces = {
    FrameMember(frame, SteelSection('HSS5x5x1/2', 'US', t), 1, 'sback')
    FrameMember(frame, SteelSection('HSS5x5x1/2', 'US', t), 2, 'sback')
    FrameMember(frame, SteelSection('HSS5x5x1/2', 'US', t), 3, 'sback')
    FrameMember(frame, SteelSection('HSS4x4x5/16', 'US', t), 4, 'sback')
};

frame.designGussetPlates();


%% Do stuff
%------------------------------------------------------------------------------%

% Pushover
tic
F = frame.pushoverForceDistribution();
pushover = frame.pushover(F, 'targetPostPeakRatio', 0.80);
fprintf('Pushover took %g seconds\n', toc)
fprintf('Analysis ended at a roof drift of %g in.\n\n', pushover.roofDrift(end));

frame.plotPushoverCurve(pushover)

% Response history
tic
load( gm_mat, 'ground_motions' );
gmID   = ground_motions(gmIndex).ID;
gmFile = scratchFile(frame,sprintf('acc%s.acc',gmID));
dt     = ground_motions(gmIndex).dt;
tEnd   = ground_motions(gmIndex).time(end);
accel  = ground_motions(gmIndex).normalized_acceleration;
dlmwrite(gmFile,accel*frame.g);


rh = frame.responseHistory(gmFile, dt, SF, tEnd, gmID, 1);
fprintf('Response history took %g seconds\n', toc)
fprintf('Analysis ended at %g seconds into the time series\n\n', rh.time(end));

figure
plot(rh.time, rh.roofDrift);
xlabel('Time (s)')
ylabel('Roof drift (in.)')
yl = ylim;
ylim([-max(abs(yl)), max(abs(yl))])
grid on

figure
plot(rh.time, rh.baseShear);
xlabel('Time (s)')
ylabel('Base shear (kip)')
yl = ylim;
ylim([-max(abs(yl)), max(abs(yl))])
grid on

figure
hold on
plot(rh.time, rh.storyDrift);
legend('Story 1', 'Story 2', 'Story 3', 'Story 4')
xlabel('Time (s)')
ylabel('Story drift (in.)')
yl = ylim;
ylim([-max(abs(yl)), max(abs(yl))])
grid on
