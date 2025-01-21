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
            *
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
    ),
    exon_like_feature AS (
        SELECT
            gene_like.name as geneName,
            gene_like.featureId as geneId,
            transcript_like_gencode_basic.featureId as transcriptId,
            genomic_data.referenceName,
            genomic_data.exonId as exonId,
            genomic_data.start as exonStart,
            genomic_data."end" as exonEnd,
            genomic_data.strand as exonStrand,
            genomic_data.attributes as exonAttributes
        FROM
            genomic_data
        JOIN transcript_like_gencode_basic ON genomic_data.parentId = transcript_like_gencode_basic.featureId
        JOIN gene_like ON transcript_like_gencode_basic.parentId = gene_like.featureId
        WHERE
            genomic_data.exonId IS NOT NULL
    ),
    sorted_exon_like_feature AS (
        SELECT
            *,
            LAG(exonEnd, 1, exonStart + 1) OVER (PARTITION BY geneId ORDER BY exonStart, exonEnd) AS exonPrevEnd ,
            exonStart + 1 >= exonPrevEnd as gap_boundary,
        FROM
            exon_like_feature
    ),
    exon_group AS (
        SELECT *,
            SUM(CASE WHEN gap_boundary THEN 1 ELSE 0 END) OVER (PARTITION BY geneId ORDER BY exonStart, exonEnd) as exon_group
        FROM sorted_exon_like_feature
    ),
    merged_exon_like_features AS (
        SELECT
            geneName,
            geneId,
            referenceName,
            MIN(exonStart)  mergedExonStart,
            MAX(exonEnd)  as mergedExonEnd,
            exonStrand as mergedExonStrand,
        FROM
            exon_group
        GROUP BY geneName, geneId, referenceName, exon_group, mergedExonStrand
    )
--     SELECT DISTINCT
--         referenceName,
--         mergedExonStart,
--         mergedExonEnd,
--         replace(geneId, 'gene:', '') as geneId,
--     FROM
--         merged_exon_like_features
--     ORDER BY referenceName, mergedExonStart, mergedExonEnd
     SELECT DISTINCT
        referenceName,
        mergedExonStart,
        mergedExonEnd,
        replace(geneId, 'gene:', '') as displayName,
        '*' as score,
        CASE
            WHEN mergedExonStrand = 'FORWARD' THEN
                '+'
            WHEN mergedExonStrand = 'REVERSE' THEN
                '-'
            ELSE
                '.'
        END
            as strand
    FROM
        merged_exon_like_features
    ORDER BY referenceName, mergedExonStart, mergedExonEnd
)
TO  '$output' (DELIMITER '\t', HEADER false)
;

