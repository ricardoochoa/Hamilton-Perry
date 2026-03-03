# **Annex: Methodology for Population Projections of Kota Semarang (2035–2050)**

## **1\. Introduction and Objective**

This document outlines the methodology used to extend the population projections for Kota Semarang, Central Java, from the year 2035 to 2050\.

The baseline data for this extension relies on the official 2020–2035 projections published by Statistics Indonesia (Badan Pusat Statistik \- BPS), which were derived from the 2020 Population Census (SP2020). The objective of this model is to generate a robust mathematical extension of the BPS data—including Minimum, Mean, and Maximum scenarios—while preserving the complex demographic assumptions embedded in the original official figures.

## **2\. Methodological Rationale and Data Constraints**

Standard demographic forecasting typically utilizes the **Cohort-Component Method (CCM)**, which projects a population by calculating births, deaths, and migration as separate, independent components.

However, running a traditional CCM from scratch requires highly granular, localized data arrays, specifically:

* Age-Specific Fertility Rates (ASFR)  
* Local Age-Specific Mortality Rates (Model Life Tables)  
* Age-Specific Net Migration Rates (ASNMR)

While BPS utilizes a deterministic CCM to generate their official projections, they only publish the *resulting* age-sex population structures and summary indicators (like Total Fertility Rate limits and Life Expectancy targets), rather than the granular age-specific arrays for individual regencies/cities. Furthermore, applying national-level models (such as the United Nations Population Prospects) directly to a specific, highly urbanized metropolitan area like Kota Semarang would result in an **ecological fallacy**—incorrectly assuming local trends mirror national averages.

To overcome these constraints, this projection employs the **Hamilton-Perry Method**.

## **3\. The Hamilton-Perry Method**

The Hamilton-Perry method is a widely recognized macroscopic variant of the Cohort-Component Method. It is explicitly designed for scenarios where historical age-sex counts are available, but detailed vital rates (births, deaths, migration) are not.

Instead of treating mortality and migration as separate inputs, the Hamilton-Perry method combines them into empirical ratios based on how specific cohorts move through time. By analyzing the BPS population structures over 5-year intervals (2020 to 2035), the method captures the "demographic DNA" of the population.

The model relies on two primary mathematical mechanisms:

### **A. Cohort Change Ratios (CCRs)**

To project the population aged 5 and older, the model calculates Cohort Change Ratios. A CCR measures the survivorship and net migration of a specific age cohort over a 5-year period.

* **Standard Formula:** ![][image1]  
  *(Where ![][image2] is population, ![][image3] is the starting age, and ![][image4] is the base year)*  
* **Open-Ended Cohort Formula (75+):** Because the final age bracket is open-ended, its calculation must account for individuals aging into the bracket as well as those already in it.  
  ![][image5]

### **B. Child-Woman Ratios (CWRs)**

Because children aged 0–4 in the target year were not yet born in the base year, CCRs cannot be used to project them. Instead, the model uses a Child-Woman Ratio, which serves as an empirical proxy for fertility.

* **Formula:** ![][image6]  
  *(Where ![][image7] represents the total female population of reproductive age)*

## **4\. Scenario Generation (Handling Uncertainty)**

Because the original BPS projection was deterministic (providing only a single point estimate), we introduced a scenario-based forecasting approach to generate a max-min range for 2050\.

Within the 2020–2035 BPS data, there are three distinct historical transition periods:

1. 2020 to 2025  
2. 2025 to 2030  
3. 2030 to 2035

The model calculates the CCRs and CWRs for every age-sex cohort across all three periods. From this variance, three parameters are extracted:

* **The Minimum Scenario (Low Bound):** Applies the lowest observed ratios, assuming slower growth, lower fertility, and/or higher out-migration.  
* **The Mean Scenario (Medium Bound):** Applies the mathematical average of the ratios, assuming the baseline trajectory continues steadily.  
* **The Maximum Scenario (High Bound):** Applies the highest observed ratios, assuming faster growth, higher fertility, and/or higher in-migration.

*Note on external factors:* BPS explicitly factored the relocation of the national capital (Ibu Kota Nusantara \- IKN) into their 2020-2035 migration models. By deriving our CCRs from the BPS data, the Hamilton-Perry model implicitly carries these sophisticated migration assumptions forward into 2050\.

## **5\. Step-by-Step Computational Process**

The projection is executed recursively in 5-year steps using an R programming script. The process follows these steps for each scenario (Min, Mean, Max):

1. **Establish Base Year:** The projection utilizes the final available BPS data point (2035) as the baseline.  
2. **Project Ages 5+:** The predetermined CCRs are multiplied against the 2035 base population to calculate the population aged 5 and older for the year 2040\.  
3. **Calculate Reproductive Base:** The projected 2040 female population aged 15–49 is aggregated.  
4. **Project Newborns (0–4):** The predetermined CWRs are multiplied against the newly calculated 2040 reproductive base to generate the 0–4 age group.  
5. **Recursive Iteration:** The completed 2040 population structure becomes the new base year. Steps 2 through 4 are repeated to project 2045, and then repeated once more to achieve the final target year of 2050\.

## **6\. External Validation (United Nations Benchmarking)**

While national-level data cannot be mathematically integrated into the local model without causing distortion, the resulting projections were validated against the **United Nations World Population Prospects (High, Low, and Estimate variants)**.

By running side-by-side visualizations of the projected working-age populations (15–64), the model confirms that the demographic trajectory of Kota Semarang behaves logically when benchmarked against the broader macroeconomic shifts projected for the Republic of Indonesia.

[image1]: <data:image/png;base64,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>

[image2]: <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAA8AAAAYCAYAAAAlBadpAAAAvElEQVR4XmNgGOFAQUFhgry8/Ecg/g/F34H4HbIYUM0qdH0oAKYQXVxRUVEeasAudDk4gGo+ji4OArgMBgOgqRFQ093R5WRkZDjxagZKXMMlCRRfDzU4AF0ODHCZDBRzhGqciC4HBzDNQPwBiN8D8Q8o/7K0tLQwuno4gPkXiJPQ5QgCoKabIM3o4kQBmJPRxYkCUM130MUJAqCmapBmoL/T0eVwAqCGyUD8WR4SsqB0/BWI/6GrGwVDGgAAbZhHbx0gjS0AAAAASUVORK5CYII=>

[image3]: <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAsAAAAYCAYAAAAs7gcTAAAAq0lEQVR4XmNgGAV0BwoKChPl5ORSkfgd8vLyNchqGBQVFcWBEpdAbKDiXKCCX0D8H8QH0meBuAeuGCYBAqKiojwgPtAAfaABFiA2kI5AVmwEYwNNLkPWDFTIAWNjAKDCT8iK8QKQQiBejC4OBkBrBEAKZGVllWHuBTpFCyYP5F9FVjwTpEBGRoYTSJ+DmqwIkgN5EqhxBVwxEDBCFYBMdAXZgMSvQ1Y4CsgGAJdwLWZxMIktAAAAAElFTkSuQmCC>

[image4]: <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAcAAAAYCAYAAAA20uedAAAAh0lEQVR4XmNgGMxAXl7+m4KCwil0cTAASv4HShagizMoKirqgySBTCa4oJycnA1Q0AuId4MkgXxfEB8sCWQUAXEJSAKI30L5RXDdUEUgXbkogiAgIyOjC7WPEV0OpGsNVBITQO17hy4OBlDJEiT+ERRJoL0qUPZPuARUoAeq+weQy4IiOTwAALDpJKA1L+E/AAAAAElFTkSuQmCC>

[image5]: <data:image/png;base64,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>

[image6]: <data:image/png;base64,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>

[image7]: <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAA8AAAAYCAYAAAAlBadpAAAA1klEQVR4XmNgGOFAQUFhl7y8/H9iMLpeOMCnAGjBKqDcb3RxGGAGaQQqOoUuAQLq6uq8cnJyB9HFwQCosQSq2QNZHMjnANFKSkr8QPkmZDk4AEp8RHcykF8lIyOjAmIbGxuziouLcyPLwwG6f4FsTXTDcAGwf7FhdIUYABgQ5SCFsrKyfjAxRUVFPaDYamR1WAFQ0Wd0W4AGpgLFNJHFsAKinYgOtLS02EAagTadRJcjCIDxOAGkGUiHo8vhBEANy6F+fQ/Eb4H4AxD/ALpgOrraUTBkAQDWOkfHf41tEwAAAABJRU5ErkJggg==>