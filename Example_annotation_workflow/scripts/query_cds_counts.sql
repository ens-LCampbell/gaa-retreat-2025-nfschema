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
    cds_like_feature AS (
        SELECT
            gene_like.name as geneName,
            gene_like.featureId as geneId,
            transcript_like_gencode_basic.featureId as transcriptId,
            genomic_data.referenceName,
            genomic_data.featureId as cdsId,
            genomic_data.start as cdsStart,
            genomic_data."end" as cdsEnd,
            genomic_data.strand as cdsStrand,
        FROM
            genomic_data
        JOIN transcript_like_gencode_basic ON genomic_data.parentId = transcript_like_gencode_basic.featureId
        JOIN gene_like ON transcript_like_gencode_basic.parentId = gene_like.featureId
        WHERE
            genomic_data.featureId LIKE '%CDS:%'
    ),
    sorted_cds_like_feature AS (
        SELECT
            cds_like_feature.geneName,
            cds_like_feature.geneId,
            cds_like_feature.referenceName,
            cds_like_feature.cdsStart AS cdsTransition,
            -- 1 to mark the beginning of a new CDS
            1 AS countChange,
        FROM cds_like_feature
        UNION ALL
        SELECT
            cds_like_feature.geneName,
            cds_like_feature.geneId,
            cds_like_feature.referenceName,
            cds_like_feature.cdsEnd AS cdsTransition,
            -- -1 to mark the end of a CDS
            -1 AS countChange,
        FROM
            cds_like_feature
        ORDER BY cds_like_feature.cdsStart
    ),
    cds_windows AS (
        -- Cumulative CDS counts using window function
        SELECT DISTINCT
            geneName,
            geneId,
            referenceName,
            cdsTransition,
            SUM(countChange) OVER (PARTITION BY geneName ORDER BY cdsTransition) AS cdsCount
        FROM
            sorted_cds_like_feature
    ),
    count_intervals AS (
    -- Define CDS count intervals
    SELECT
        geneName,
        geneId,
        referenceName,
        cdsTransition as intervalStart,
        LEAD(cdsTransition) OVER (PARTITION BY geneName ORDER BY cdsTransition) as intervalEnd,
        cdsCount

    FROM
        cds_windows
    ),
    gene_like_transcript_like_gencode_basic_total AS (
        SELECT
            gene_like.featureId as geneId,
            COUNT(transcript_like_gencode_basic.transcriptId) as transcriptTotal
        FROM
            transcript_like_gencode_basic
            JOIN gene_like ON transcript_like_gencode_basic.parentId = gene_like.featureId
        GROUP BY
            gene_like.featureId
    )
    SELECT DISTINCT
        referenceName,
        intervalStart,
        intervalEnd,
        replace(count_intervals.geneId, 'gene:', '') as geneId,
        round(cdsCount / gene_like_transcript_like_gencode_basic_total.transcriptTotal, 4) AS cdsFrequency
    FROM
        count_intervals
        JOIN gene_like_transcript_like_gencode_basic_total ON count_intervals.geneId = gene_like_transcript_like_gencode_basic_total.geneId
        WHERE
            intervalEnd IS NOT NULL
            AND cdsCount > 0
        ORDER BY
            referenceName, intervalStart
)
TO  '$output' (FORMAT 'PARQUET', CODEC 'ZSTD')
;

