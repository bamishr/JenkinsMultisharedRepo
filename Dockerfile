FROM r-base
COPY  test.R .
CMD ["Rscript", "test.R"]
