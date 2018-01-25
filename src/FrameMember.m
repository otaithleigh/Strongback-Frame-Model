classdef FrameMember < handle

properties
    material        % Material the member is made of
    shape           % Steel shape used for the member
    story           % Story the member is located on
    type
    nFibers         % Number of fibers per section
    orientation = 'strong'     % Orientation of the member ('strong' or 'weak')

    storyHeight
    bracePos
    bayWidth

    includeResidualStresses
    residualStressFactor
    nResidualStressSectors
end

properties (Dependent)
    alpha
end

methods

function obj = FrameMember(frame, shape, story, type)
    obj.storyHeight = frame.storyHeight(story);
    obj.bracePos    = frame.bracePos;
    obj.bayWidth    = frame.bayWidth;
    obj.nFibers     = frame.nFibers;

    obj.shape       = shape;
    obj.story       = story;

    obj.includeResidualStresses = frame.includeResidualStresses;
    obj.residualStressFactor    = frame.residualStressFactor;
    obj.nResidualStressSectors  = frame.nResidualStressSectors;

    switch lower(type)
    case 'column'
        obj.material = frame.ColumnMat;
    case 'beam'
        obj.material = frame.BeamMat;
    case 'brace'
        obj.material = frame.BraceMat;
    case 'sback'
        obj.material = frame.BraceMat;
    case 'tie'
        obj.material = frame.BraceMat;
    case 'lean'
        obj.material = SteelDesign.SteelMaterial('Elastic');
    otherwise
        error('Invalid member type: %s', type)
    end

    obj.type = type;
end

function alpha = get.alpha(obj)
    switch obj.type
    case 'beam'
        alpha = 0;
    case {'column', 'tie'}
        alpha = 90;
    case 'brace'
        alpha = atand(obj.storyHeight/(obj.bracePos*obj.bayWidth) );
    case 'sback'
        alpha = atand(obj.storyHeight/( (1-obj.bracePos)*obj.bayWidth ) );
    end
end

function code = OpenSeesSection(obj, secTag, matTag)
    Es = obj.material.Es;
    Fy = obj.material.Fy;
    Fu = obj.material.Fu;
    switch obj.shape.Type
    case 'W'
        frc = -obj.residualStressFactor*Fy;
        nSectors = obj.nResidualStressSectors;
        nf1 = obj.nFibers;
        nf2 = obj.orientation;
        d = obj.shape.d;
        tw = obj.shape.tw;
        bf = obj.shape.bf;
        tf = obj.shape.tf;

        mat = sprintf('-Steel02 %i %g %g 0.003', matTag, Es, Fy);
        if obj.includeResidualStresses
            residual = sprintf(' -Lehigh %g %i', frc, nSectors);
        else
            residual = sprintf(' -Lehigh 0 0');
        end
        code = sprintf('OpenSeesComposite::wfSection %i %i %s %g %g %g %g %s%s',...
            secTag, nf1, nf2, d, tw, bf, tf, mat, residual);
    case 'HSS'
        t  = obj.shape.tdes;
        B  = obj.shape.B;
        D  = obj.shape.Ht;
        units = obj.shape.Units;
        nf1 = obj.nFibers;
        nf2 = obj.orientation;

        code = sprintf('OpenSeesComposite::recthssSection %i %i %i %s %s %g %g %g %g %g %g -SteelMaterialType %s',...
            secTag, matTag, nf1, nf2, units, D, B, t, Fy, Fu, Es, 'Steel02');
    end
end

end


end
