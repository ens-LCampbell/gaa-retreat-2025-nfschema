COPY (
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
    five_prime_utr_like_feature AS (
        SELECT
            gene_like.name as geneName,
            gene_like.featureId as geneId,
            transcript_like_gencode_basic.featureId as transcriptId,
            genomic_data.referenceName,
            genomic_data.start as five_utrStart,
            genomic_data."end" as five_utrEnd,
            genomic_data.strand as five_utrStrand,
        FROM
            genomic_data
        JOIN transcript_like_gencode_basic ON genomic_data.parentId = transcript_like_gencode_basic.featureId
        JOIN gene_like ON transcript_like_gencode_basic.parentId = gene_like.featureId
        WHERE
            genomic_data.featureType = 'five_prime_UTR'
    ),
    tss AS (
    SELECT DISTINCT
        referenceName,
        CASE
        WHEN five_utrStrand = 'FORWARD' THEN
            MIN(five_utrStart) OVER (PARTITION BY transcriptId)
        ELSE
            MAX(five_utrEnd) OVER (PARTITION BY transcriptId) - 1
        END
            as tssStart,
        CASE
        WHEN five_utrStrand = 'FORWARD' THEN
            MIN(five_utrStart) OVER (PARTITION BY transcriptId) + 1
        ELSE
            MAX(five_utrEnd) OVER (PARTITION BY transcriptId)
        END
            as tssEnd,
        replace(geneId, 'gene:', '') as geneId,
        five_utrStrand as strand,
    FROM
        five_prime_utr_like_feature
    ),
    first_exon AS (
    SELECT
            genomic_data.referenceName,
            CASE
            WHEN genomic_data.strand = 'FORWARD' THEN
                MIN(genomic_data.start) OVER (PARTITION BY transcript_like_gencode_basic.featureId)
            ELSE
                MAX(genomic_data.end) OVER (PARTITION BY transcript_like_gencode_basic.featureId) - 1
            END
                as tssStart,
            CASE
            WHEN genomic_data.strand = 'FORWARD' THEN
                MIN(genomic_data.start) OVER (PARTITION BY transcript_like_gencode_basic.featureId) + 1
            ELSE
                MAX(genomic_data.end) OVER (PARTITION BY transcript_like_gencode_basic.featureId)
            END
                as tssEnd,
            replace(gene_like.geneId, 'gene:', '') as geneId,
            genomic_data.strand,
    FROM
        genomic_data
        JOIN transcript_like_gencode_basic ON genomic_data.parentId = transcript_like_gencode_basic.featureId
        JOIN gene_like ON transcript_like_gencode_basic.parentId = gene_like.featureId
        WHERE
            genomic_data.exonId IS NOT NULL
            AND map_extract(genomic_data.attributes, 'rank')[1] = '1'
    ),
    all_tss AS (
    SELECT
        *
    FROM
        tss
    UNION
    SELECT
        *
    FROM
        first_exon
    )
    SELECT DISTINCT * FROM all_tss
    ORDER BY referenceName, tssStart, tssEnd
)
TO  '$output' (FORMAT 'PARQUET', CODEC 'ZSTD' )
;
