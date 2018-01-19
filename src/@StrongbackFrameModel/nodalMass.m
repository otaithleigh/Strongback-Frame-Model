function mass = nodalMass(obj, story, location)
%nodalMass

s_joist = obj.bayWidth/(obj.nJoists+1);

DL_floor = obj.deadLoad(story);
DL_beam  = DL_floor*s_joist/2;
DL_col   = DL_floor*obj.bayWidth*obj.bayWidth/2 - DL_beam*obj.bayWidth/2;
DL_lean  = DL_floor*obj.nBays*obj.bayWidth*obj.nBays*obj.bayWidth/2 - 2*DL_col - DL_beam*obj.bayWidth;

switch lower(location)
case 'left'
    DL = DL_col + DL_beam*obj.bayWidth/2;
case 'right'
    DL = DL_col + DL_beam*obj.bayWidth/2;
case 'lean'
    DL = DL_lean;
otherwise
    error('Invalid mass location: %s', location)
end

mass = DL/obj.g;

end
