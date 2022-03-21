--1. Looking at data
SELECT *
FROM PortfolioProject..NashvilleHousing



--2. Standardising date format
--SELECT SaleDate, CONVERT(date,SaleDate)
--FROM PortfolioProject..NashvilleHousing

--UPDATE PortfolioProject..NashvilleHousing
--SET SaleDate = CONVERT(date,SaleDate)
--*This does not update the table*

--Adding new column for standardised date
ALTER TABLE PortfolioProject..NashvilleHousing
ADD SaleDateConverted Date;

--Updating the new column
UPDATE PortfolioProject..NashvilleHousing
SET SaleDateConverted = CONVERT(date,SaleDate)

--Checking
SELECT SaleDateConverted, CONVERT(date,SaleDate)
FROM PortfolioProject..NashvilleHousing
--Standardised date column is created

----*Another way (Altering table and changing 'SaleDate' column format)*
--ALTER TABLE PortfolioProject..NashvilleHousing
--ALTER COLUMN [SaleDate]date



--3. Populating property address data
--Checking empty PropertyAddress
SELECT *
FROM PortfolioProject..NashvilleHousing
WHERE PropertyAddress is NULL
ORDER BY ParcelID

--Joining the same table to check empty PropertyAddress with identical ParcelID
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject..NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is NULL

--Replacing empty PropertyAddress with existing PropertyAddress
UPDATE a --Has to use Alias
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject..NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is NULL



--4. Splitting address into separate columns
--4.1. Splitting PropertyAddress into columns
SELECT PropertyAddress
FROM PortfolioProject..NashvilleHousing

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) AS Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress)) AS City
FROM PortfolioProject..NashvilleHousing

--Adding new column for street
ALTER TABLE PortfolioProject..NashvilleHousing
ADD PropertySplitAddress nvarchar(255);

--Updating the new column
UPDATE PortfolioProject..NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)

--Adding new column for city
ALTER TABLE PortfolioProject..NashvilleHousing
ADD PropertySplitCity nvarchar(255);

--Updating the new column
UPDATE PortfolioProject..NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress))

--Checking new columns
SELECT *
FROM PortfolioProject..NashvilleHousing
--New columns are set for PropertyAddress

--4.2. Splitting OwnerAddress into columns
SELECT OwnerAddress
FROM PortfolioProject..NashvilleHousing

--Splitting by ','
SELECT 
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)
FROM PortfolioProject..NashvilleHousing

--Adding new columns
ALTER TABLE PortfolioProject..NashvilleHousing
ADD OwnerSplitAddress nvarchar(255);
ALTER TABLE PortfolioProject..NashvilleHousing
ADD OwnerSplitCity nvarchar(255);
ALTER TABLE PortfolioProject..NashvilleHousing
ADD OwnerSplitState nvarchar(255);

--Updating new columns
UPDATE PortfolioProject..NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)
UPDATE PortfolioProject..NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)
UPDATE PortfolioProject..NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
--New columns are set for OwnerAddress



--5. Standardising SoldAsVacant column
--Checking column
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM PortfolioProject..NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

--Replacing 'Y' with 'Yes' and 'N' with 'No'
SELECT SoldAsVacant,
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	 WHEN SoldAsVacant = 'N' THEN 'No'
	 ELSE SoldAsVacant
	 END
FROM PortfolioProject..NashvilleHousing
GROUP BY SoldAsVacant

--Updating the column
UPDATE NashvilleHousing
SET SoldAsVacant = 
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	 WHEN SoldAsVacant = 'N' THEN 'No'
	 ELSE SoldAsVacant
	 END
FROM PortfolioProject..NashvilleHousing
--The column is updated



--6. Removing duplicates
WITH RowNumCTE AS
(
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference ORDER BY UniqueID) row_num
FROM PortfolioProject..NashvilleHousing
)
SELECT *
FROM RowNumCTE
WHERE row_num >1



--7. Removing unused columns
SELECT *
FROM PortfolioProject..NashvilleHousing

ALTER TABLE PortfolioProject..NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate