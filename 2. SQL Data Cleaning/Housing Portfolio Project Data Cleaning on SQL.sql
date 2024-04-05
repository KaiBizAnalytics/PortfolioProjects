/*

Cleaning Data in SQL Queries

Skills used: Self Joins, CTE's, Substring Operations, Windows Functions, Converting Data Types, Flagging Duplicates, Deleting Unused Data

*/

SELECT *
FROM PortfolioProject..NashvilleHousing

--------------------------------------------------------------------------------

-- Standardize Date Format

SELECT SaleDate, CONVERT(DATE, SaleDate)
FROM PortfolioProject..NashvilleHousing

ALTER TABLE PortfolioProject..NashvilleHousing
ALTER COLUMN SaleDate Date


--------------------------------------------------------------------------------

-- Populate Property Address data

SELECT *
FROM PortfolioProject..NashvilleHousing
ORDER BY ParcelID


SELECT tbl1.ParcelID, tbl1.PropertyAddress, tbl2.ParcelID, tbl2.PropertyAddress,
ISNULL(tbl1.PropertyAddress, tbl2.PropertyAddress)
FROM PortfolioProject..NashvilleHousing tbl1
JOIN PortfolioProject..NashvilleHousing tbl2
	ON tbl1.ParcelID = tbl2.ParcelID
	AND tbl1.[UniqueID ] <> tbl2.[UniqueID ]
WHERE tbl1.PropertyAddress IS NULL

UPDATE tbl1
SET PropertyAddress = ISNULL(tbl1.PropertyAddress, tbl2.PropertyAddress)
FROM PortfolioProject..NashvilleHousing tbl1
JOIN PortfolioProject..NashvilleHousing tbl2
	ON tbl1.ParcelID = tbl2.ParcelID
	AND tbl1.[UniqueID ] <> tbl2.[UniqueID ]
WHERE tbl1.PropertyAddress IS NULL


--------------------------------------------------------------------------------

-- Breaking out Address Into Individual Columns (Address, City, State)

SELECT PropertyAddress
FROM PortfolioProject..NashvilleHousing

SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) AS Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) AS City
FROM PortfolioProject..NashvilleHousing

ALTER TABLE PortfolioProject..NashvilleHousing
ADD PropertySplitAddress nvarchar(255);

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1)

ALTER TABLE PortfolioProject..NashvilleHousing
ADD PropertySplitCity nvarchar(255);

UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))



SELECT OwnerAddress
FROM PortfolioProject..NashvilleHousing

SELECT 
PARSENAME(REPLACE(OwnerAddress,',', '.'), 3),
PARSENAME(REPLACE(OwnerAddress,',', '.'), 2),
PARSENAME(REPLACE(OwnerAddress,',', '.'), 1)
FROM PortfolioProject..NashvilleHousing

ALTER TABLE PortfolioProject..NashvilleHousing
ADD OwnerSplitAddress nvarchar(255);
ALTER TABLE PortfolioProject..NashvilleHousing
ADD OwnerSplitCity nvarchar(255);
ALTER TABLE PortfolioProject..NashvilleHousing
ADD OwnerSplitState nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',', '.'), 3)
UPDATE NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',', '.'), 2)
UPDATE NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',', '.'), 1)




--------------------------------------------------------------------------------

-- Change Y and N to Yes and No in "Sold as Vacant" field

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM PortfolioProject..NashvilleHousing
GROUP BY SoldAsVacant
ORDER by 2


SELECT SoldAsVacant,
	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		 WHEN SoldAsVacant = 'N' THEN 'No'
		 END
FROM PortfolioProject..NashvilleHousing


UPDATE NashvilleHousing
SET SoldAsVacant = 
				 CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
				 WHEN SoldAsVacant = 'N' THEN 'No'
				 END


--------------------------------------------------------------------------------

-- Remove Duplicates
WITH RowNumCTE AS
(
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY UniqueID
					) row_num
FROM PortfolioProject..NashvilleHousing
)
-- In daily practice I would set up a disposition table that has all the unique ID, and set the disposition code to disposable for IDs where row_num > 1
SELECT *
FROM RowNumCTE
WHERE row_num > 1


--------------------------------------------------------------------------------

-- Delete Unused Columns


ALTER TABLE PortfolioProject..NashvilleHousing
DROP COLUMN OwnerAddress, PropertyAddress, TaxDistrict



-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------

--- Importing Data using OPENROWSET and BULK INSERT	(ETL)


sp_configure 'show advanced options', 1;
RECONFIGURE;
GO
sp_configure 'Ad Hoc Distributed Queries', 1;
RECONFIGURE;
GO


USE PortfolioProject 

GO 

EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'AllowInProcess', 1 

GO 

EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'DynamicParameters', 1 

GO 


-- Using BULK INSERT

USE PortfolioProject;
GO
BULK INSERT NashvilleHousing FROM 'D:\Portfolio Project\PortfolioProjects\2. SQL Data Cleaning\Nashville Housing Data for Data Cleaning (reuploaded).xlsx'
   WITH (
      FIELDTERMINATOR = ',',
      ROWTERMINATOR = '\n'
);
GO


-- Using OPENROWSET
USE PortfolioProject;
GO
SELECT * INTO NashvilleHousing
FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0',
    'Excel 12.0; Database=D:\Portfolio Project\PortfolioProjects\2. SQL Data Cleaning\Nashville Housing Data for Data Cleaning (reuploaded).xlsx', [Sheet1$]);
GO

