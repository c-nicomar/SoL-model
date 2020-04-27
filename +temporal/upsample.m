function upsampledArray = upsample( array, factor )
%UPSAMPLE Upsamples an array by holding each value on for the specified
%factor

matrix = repmat(array, factor, 1);
upsampledArray = matrix(:);

end

