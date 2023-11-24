//! Benchmarking setup for pallet-sugondat-blobs
use super::*;

#[allow(unused)]
use crate::Pallet as Blobs;
#[allow(unused)]
use frame_benchmarking::v2::{benchmarks, impl_benchmark_test_suite, whitelisted_caller};
use frame_support::{traits::Get, BoundedVec};
use frame_system::RawOrigin;
use sp_std::vec;

/* Command to run the benchmark:
 ./target/release/sugondat-node benchmark pallet \
 --dev \
 --pallet pallet_sugondat_blobs \
 --extrinsic '*' \
 --steps 10 \
 --repeat 20 \
 --template sugondat-chain/pallets/blobs/src/frame-weight-template.hbs \
 --output sugondat-chain/pallets/blobs/src/weights_with_new_setup.rs
*/

#[benchmarks]
mod benchmarks {
    use super::*;

    #[benchmark]
    // x represent the amount of BlobsMetadata already stored in BlobList
    // while y is the size of the blob in bytes
    fn submit_blob(
        x: Linear<0, { T::MaxBlobs::get() - 1 }>,
        y: Linear<1, { T::MaxBlobSize::get() }>,
    ) {
        let caller: T::AccountId = whitelisted_caller();

        let mut namespace_id: u32;
        for namespace_id in 0..x {
            Blobs::<T>::submit_blob(
                RawOrigin::Signed(caller.clone()).into(),
                namespace_id,
                namespace_id
                    .to_le_bytes()
                    .to_vec()
                    .try_into()
                    .expect("Impossible convert blob into BoundedVec"),
            )
            .expect("Preparation Extrinsic failed");
        }
        namespace_id = x;

        // Create a random blob that needs to be hashed on chain
        let blob: BoundedVec<u8, T::MaxBlobSize> = vec![23u8]
            .repeat(y as usize)
            .try_into()
            .expect("Impossible convert blob into BoundedVec");

        #[extrinsic_call]
        _(RawOrigin::Signed(caller), namespace_id, blob);

        // Check that an item is inserted in the BlobList and
        // the new value stored in TotalBlobSize is correct
        assert_eq!(BlobList::<T>::get().len(), x as usize + 1);
        assert_eq!(TotalBlobsSize::<T>::get(), (x * 4) + y);
    }

    impl_benchmark_test_suite!(Blobs, crate::mock::new_test_ext(), crate::mock::Test);
}
