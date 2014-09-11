function match = ffourier(featp, partfilters_fft)
    
    featp_fft = fft(featp); 

    for i = 1:length(partfilters_fft)
        match{i} = feat_fft.*partfilters_fft;
    end
    
end