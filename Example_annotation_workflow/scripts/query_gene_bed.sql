COPY
(
    WITH 
    genomic_data AS (
        SELECT featureId,
           sampleId,
           name,
           source,
           featureType,
           referenceName,
           start,
           "end",
           strand,
           phase,
           geneId,
           transcriptId,
           exonId,
           list_first(parentIds) as parentId,
           attributes,
    FROM
        read_parquet('$genomic_annotation_parquet')
    ),
    gene_like AS (
        SELECT
            *,
            map_extract(attributes, 'description')[1] as raw_description,
        FROM
            genomic_data
        WHERE
            geneId IS NOT NULL
    ),
    transcript_like_gencode_basic
        AS (
        SELECT
            *,
            CAST(map_values(genomic_data.attributes) AS TEXT) AS attr_vls
        FROM
            genomic_data
        WHERE
            transcriptId IS NOT NULL
            AND attr_vls LIKE '%gencode_basic%'
            AND (
                attr_vls LIKE '%lncRNA%'
                OR attr_vls LIKE '%protein_coding%'
                OR attr_vls LIKE '%retained_intron%'
                OR attr_vls LIKE '%protein_coding_LoF%'
            )
    )
    SELECT DISTINCT
       gene_like.referenceName,
       gene_like.start as geneStart,
       gene_like."end" as geneEnd,
       CASE
       WHEN gene_like.name IS NOT NULL THEN
            concat(gene_like.geneId, '.' , map_extract(gene_like.attributes, 'version')[1] , ';', gene_like.name)
       ELSE
            concat(gene_like.geneId, '.' , map_extract(gene_like.attributes, 'version')[1])
       END as display_name,
        '*' as score,
        CASE
            WHEN gene_like.strand = 'FORWARD' THEN
                '+'
            WHEN gene_like.strand = 'REVERSE' THEN
                '-'
            ELSE
                '.'
        END
            as strand
    FROM
        gene_like
        JOIN transcript_like_gencode_basic ON gene_like.featureId = transcript_like_gencode_basic.parentId
    ORDER BY  gene_like.referenceName, geneStart, geneEnd
    )
TO  '$output' (DELIMITER '\t', HEADER false)
;

