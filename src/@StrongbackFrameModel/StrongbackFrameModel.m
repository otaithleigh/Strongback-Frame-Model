classdef StrongbackFrameModel < OpenSeesAnalysis
%StrongbackFrameModel  OpenSees frame-level model of strongback.

properties
% General properties -----------------------------------------------------------

g                       % Acceleration due to gravity
units                   % Units of the model: force, length, time
seismicDesignCategory   % FEMA P695 seismic design category
fundamentalPeriod       % Fundamental period
respModCoeff            % Response modification coefficient (R)
impFactor               % Seismic importance factor (I_e)

% Geometric properties (global) ------------------------------------------------

nStories        % Number of stories
storyHeight     % Vector of floor heights
nBays           % Number of bays in each direction
bayWidth        % Width of each bay
nJoists         % Number of gravity-load-carrying joists per bay

bracePos = 0.5  % Position of brace intersection with beams, as a ratio of bay width
nBraceEle       % Number of elements per brace
nColumnEle      % Number of elements per column
nBeamEle        % Number of elements per beam (from column to brace)
imperf = 0      % Ratio of length used for initial brace imperfections

% Frame loading ----------------------------------------------------------------

deadLoad        % Vector of total distributed dead loads per floor
liveLoad        % Vector of total distributed live loads per floor

% Section properties -----------------------------------------------------------
% The following should be cell vectors of `FrameMember`s.

LeftColumns     % Columns on the left side of the frame
RightColumns    % Columns on the right side of the frame
FrameBeams      % Beam sections
LeftBraces      % Diagonal braces
RightBraces     % Diagonal braces in the strongback
TieBraces       % Vertical ties in the strongback

GussetPlates                    % Cell containing gusset plate definitions. {story, side, num}
GussetPlateModel = 'pinned'     % Model used for gusset plate springs (pinned, fixed, spring, elastic)

% Elastic member switches

elasticLinearBraces = false;
elasticLinearBeams  = false;
elasticLinearCols   = false;

% Element options

elementFormulation = 'force'    % Nonlinear element type: 'force', 'displacement', or 'mixed'
elementIterative   = false      % Select whether to use iterative element formulation
elementIterations  = 10         % Number of iterations for iterative element formulation
elementTolerance   = 1e-12      % Tolerance for iterative element formulation

leftColumnFixity  = 'pinned'    % Fixity of the base of the left column line
rightColumnFixity = 'pinned'    % Fixity of the base of the right column line

% Material properties ----------------------------------------------------------

ColumnMat = SteelDesign.SteelMaterial('A992')
BeamMat   = SteelDesign.SteelMaterial('A992')
BraceMat  = SteelDesign.SteelMaterial('A500 Gr. C')
PlateMat  = SteelDesign.SteelMaterial('A572 Gr. 50', 'Plate')

rigidE = 1e12; % Elastic modulus used for "rigid" beam-columns

% Analysis options -------------------------------------------------------------

optionsGravityLoads = OpenSees.GravityLoadOptions
optionsPushover     = OpenSees.PushoverOptions
optionsResponseHistory = OpenSees.ResponseHistoryOptions

% Geometric transformation used for analysis: Linear, PDelta, or Corotational
transfType {mustBeMember(transfType, {'Linear', 'PDelta', 'Corotational'})} = 'PDelta'

nIntPoints = 5                          % Number of integration points per element
nFibers = 20
includeExplicitPDelta = true            % Select whether to include gravity loads on the frame
includeGeometricImperfections = false   % Select whether to include geometric imperfections (braces only)
includeResidualStresses = true          % Select whether to include residual stresses (W-sections only)
residualStressFactor = 0.3              % Maximum compressive residual stress factor
nResidualStressSectors = 10

end


properties (Dependent) %--------------------------------------------------------
    storyMass       % Total mass of each story
    nBraceNodes     % Number of nodes that comprise a brace

end

methods
%##############################################################################%

function obj = StrongbackFrameModel()
%StrongbackFrameModel  Constructor
end

function storyMass = get.storyMass(obj)
    storyMass = zeros(obj.nStories, 1);
    for i = 1:obj.nStories
        storyMass(i) = obj.nodalMass(i, 'left') ...
                     + obj.nodalMass(i, 'right') ...
                     + obj.nodalMass(i, 'lean');
    end
end

function nBraceNodes = get.nBraceNodes(obj)
    nBraceNodes = obj.nBraceEle + 3;
end

function n = nBeamNodes(obj,story)
    if mod(story,2) == 0
        n = 3 + 2*(obj.nBeamEle-1);
    else
        n = 7 + 2*(obj.nBeamEle-1);
    end
end


end %methods


methods (Static)
%==============================================================================%
function t = beamCenterNode(story)
    if mod(story,2) == 0
        t = 1;
    else
        t = 1;
    end
end

function t = beamLeftEnd(story)
    if mod(story,2) == 0
        t = 2;
    else
        t = 2;
    end
end

function t = beamRightEnd(story)
    if mod(story,2) == 0
        t = 3;
    else
        t = 7;
    end
end

function t = tag(kind, story, num)
%tag  Retrieve the appropriate OpenSees tag
%
%   t = tag(kind, story, num)
%
    switch lower(kind)
    case 'left'
        start = 0;
    case 'right'
        start = 1;
    case 'lean'
        start = 2;
    case 'beam'
        start = 3;
    case 'brace'
        start = 4;
    case 'sback'
        start = 5;
    case 'tie'
        start = 6;
    case 'rigidend'
        start = 7;
    case 'spring'
        start = 8;
    otherwise
        error('Invalid node type: %s', kind)
    end

    t = 1000*start + 100*story + num;
end

end %methods (Static)

end %classdef
